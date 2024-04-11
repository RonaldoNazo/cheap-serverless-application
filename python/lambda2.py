import boto3
import time, os

ecs_client = boto3.client('ecs')
ec2_client = boto3.client('ec2')
apigateway_client = boto3.client('apigatewayv2')


ecs_cluster =  os.environ['ECS_CLUSTER'] 
ecs_task_definition = os.environ['ECS_TASK_DEFINITION']
api_gateway_id = os.environ['API_GATEWAY_ID'] 
httpIntegrationId = os.environ['HTTP_INTEGRATION_ID']


#Start 1 ecs task in a cluster
def run_task(cluster_name, task_definition, subnet_ids, security_group_ids):
    response = ecs_client.run_task(
        cluster=cluster_name,
        taskDefinition=task_definition,
        count=1,
        launchType='FARGATE',
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': subnet_ids,
                'securityGroups': security_group_ids,
                'assignPublicIp': 'ENABLED'
            }
        }
    )
    return response
def get_task_eni(cluster_name, task_arn):
    task_description = ecs_client.describe_tasks(cluster=cluster_name, tasks=[task_arn])
    return task_description['tasks'][0]['attachments'][0]['details'][1]['value']

def get_task_public_ip(eni_id):
    response = ec2_client.describe_network_interfaces(
        NetworkInterfaceIds=[eni_id]
    )
    return response['NetworkInterfaces'][0]['Association']['PublicIp']

#update apigateway integrationuri to new ip
def update_api_gateway_integration_uri(api_gateway_id,intagrationId,newUri):
    try:
      response = apigateway_client.update_integration(
        ApiId=api_gateway_id,
        IntegrationId=intagrationId,
        IntegrationType='HTTP_PROXY',
        IntegrationUri=newUri,
        IntegrationMethod='ANY'
      )
      return True
    except Exception as e:
      print(e)
      return False

def check_task_if_ready(cluster_name, task_arn):
    task_description = ecs_client.describe_tasks(cluster=cluster_name, tasks=[task_arn])
    return task_description['tasks'][0]['lastStatus'] == 'RUNNING'

def lambda_handler(event, context):
    try:
        task_response = run_task(ecs_cluster, ecs_task_definition, ['subnet-04cd345a071784da1'], ['sg-06ca93775dcbeab71'])
        task_arn = task_response['tasks'][0]['containers'][0]['taskArn']
        # integrationId = get_api_gateway_integration(api_gateway_id)
        #Wait 10 seconds for it to create a nic public ip
        time.sleep(10)

        #Get the public ip of the nic
        public_ip = get_task_public_ip(get_task_eni(ecs_cluster, task_arn))

        #Check not more than 50 seconds if the task is ready
        for i in range(10):
            if check_task_if_ready(ecs_cluster, task_arn):
                break
            time.sleep(5)

        update_api_gateway_integration_uri(api_gateway_id,httpIntegrationId,f'http://{public_ip}/'+'{proxy}')
        print('Integration Updated Successfully...')
        return False
    except Exception as e:
        print(e)
        return True
    
if __name__ == "__main__":
    print(lambda_handler({}, {}))
