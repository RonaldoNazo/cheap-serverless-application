import boto3
import os

ecs_client = boto3.client('ecs')
apigateway_client = boto3.client('apigatewayv2')

ecs_cluster =  os.environ['ECS_CLUSTER'] 
api_gateway_id = os.environ['API_GATEWAY_ID'] 
lambdaIntegrationId = os.environ['LAMBDA_INTEGRATION_ID']
httpIntegrationId = os.environ['HTTP_INTEGRATION_ID']
s3_website = os.environ['S3_WEBSITE']

# Update the apigateway integration to a lambda function
def update_api_gateway_integration_to_lambda(api_gateway_id,intagrationId,newUri):
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
# Stop all ecs tasks in the cluster
def stop_all_tasks(cluster_name):
    response = ecs_client.list_tasks(
        cluster=cluster_name,
        desiredStatus='RUNNING'
    )
    if len(response['taskArns']) > 0:
        for task in response['taskArns']:
            ecs_client.stop_task(
                cluster=cluster_name,
                task=task
            )
    return True

def create_get_api_gateway_route(rest_api_id, route_key='GET /'):
    try:
        response = apigateway_client.create_route(
        ApiId=rest_api_id,
        RouteKey=route_key
        )
        return response['RouteId']
    except Exception as e:
      print(e)
      return None

def update_api_gateway_route(rest_api_id, route_id, route_key='GET /', integrationId='httpd'):
    try:
        response = apigateway_client.update_route(
        ApiId=rest_api_id,
        RouteId=route_id,
        RouteKey=route_key,
        Target= 'integrations/' + integrationId
        )
        return response['RouteId']
    except Exception as e:
      print(e)
      return None

def lambda_handler(event, context):
  # Step 1: Stop all ecs tasks
  stop_all_tasks(ecs_cluster)

  # Step 2: Create Get route in API Gateway
  route_id = create_get_api_gateway_route(api_gateway_id,'GET /')
  if route_id is None:
      print('Failed to create route')
      return False

  # Step 3: Update the api gateway route for the integration to the lambda function
  update_api_gateway_route(api_gateway_id, route_id, 'GET /', lambdaIntegrationId)

  
  # Step 4: Update the integration of ANY to a s3 bucket website
  update_api_gateway_integration_to_lambda(api_gateway_id, httpIntegrationId, s3_website)
  print('Process Completed Sucessfully')
  return True

if __name__ == "__main__":
  lambda_handler(None, None)
