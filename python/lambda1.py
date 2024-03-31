import json, os
import boto3
# from lambda2 import lambda_handler as lambda2_handler

# Initialize the clients
apigateway_client = boto3.client('apigatewayv2')
lambda_client = boto3.client('lambda')

api_gateway_id = os.environ['API_GATEWAY_ID'] 
httpIntegrationId = os.environ['HTTP_INTEGRATION_ID']
s3_website = os.environ['S3_WEBSITE']
function_name = os.environ['LAMBDA2_NAME']


# Step 4: Return an HTML page
html_content = """
<!DOCTYPE html>
<html>
<head>
  <title>Welcome</title>
  <style>
    /* CSS to center the content */
    body,
    html {
      height: 100%;
      margin: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      flex-direction: column;
      text-align: center;
    }
    a {
      color: #007bff;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
  <script>
    // JavaScript code for countdown, autoreload, and setting the domain dynamically
    let countdown = 30; // countdown starting from 10 seconds
    function updateCountdown() {
      // Update the display with the current countdown value
      document.getElementById('countdown').innerText = `Page reloads in ${countdown} seconds...`;

      if (countdown === 0) {
        // Reload the page when countdown reaches 0
        window.location.reload();
      } else {
        // Decrease countdown by 1 every second
        countdown--;
        setTimeout(updateCountdown, 1000);
      }
    }
    function setDomain() {
      // Set the domain dynamically
      document.getElementById('domain').innerText = window.location.hostname;
    }
    window.onload = function () {
      updateCountdown(); // Start countdown when the page loads
      setDomain(); // Set the domain based on where the page is hosted
    };
  </script>
</head>
<body>
  <h1>Hello in <span id="domain"></span></h1>
  <p>This page is using a Cheap Serverless Application. More information on: <a href="https://github.com/RonaldoNazo/cheap-serverless-application"
      target="_blank">GitHub</a></p>
  <p id="countdown">Page reloads in 30 seconds...</p>
</body>
</html>
"""

def get_http_api_gateway_integration(rest_api_id):
    try:
        response = apigateway_client.get_integrations(
        ApiId=rest_api_id
        )
        for item in response['Items']:
            if item['IntegrationType'] == "HTTP_PROXY":
             return  item['IntegrationId']
    except Exception as e:
      print(e)
      return None

def get_api_gateway_route(rest_api_id, route_key='GET /'):
    try:
        response = apigateway_client.get_routes(
        ApiId=rest_api_id
        )
        items = response['Items']
        for item in items:
            if item['RouteKey'] == route_key:
             routeId = item['RouteId']
             return routeId
    except Exception as e:
      print(e)
      return None

def lambda_handler(event, context):
    # Step 1: Update API Gateway integration to point to an S3 bucket website
    # integrationId = get_http_api_gateway_integration(api_gateway_id)
    
    try:
        apigateway_client.update_integration(
        ApiId=api_gateway_id,
        IntegrationId=httpIntegrationId,
        IntegrationType='HTTP_PROXY',
        IntegrationUri=s3_website,
        IntegrationMethod='GET'
        )
    except Exception as e:
        print(f"Failed to update API Gateway integration: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to update API Gateway integration')
        }
    # Step 2: Delete the basic GET route from the API Gateway
    lambda_route_id = get_api_gateway_route(api_gateway_id,'GET /')
    if lambda_route_id is None:
        print('Something is cooking...')
        return {
        'statusCode': 200,
        'headers': {'Content-Type': 'text/html'},
        'body': html_content
        }
    try:
        apigateway_client.delete_route(
        ApiId=api_gateway_id,
        RouteId=lambda_route_id
        )
    except Exception as e:
        print(f"Failed to delete API Gateway route: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to delete API Gateway route')
        }

    # Step 3: Trigger another Lambda function
    try:
        lambda_client.invoke(
            FunctionName=function_name,
            InvocationType='Event',  # Use 'RequestResponse' if you need the response from the invoked function
            Payload=json.dumps({'key': 'value'}),  # Pass any required payload to the target function
        )
        print('Invoking lambda2_handler')
        # lambda2_handler({}, {}) #for local testing

    except Exception as e:
        print(f"Failed to invoke target Lambda function: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to invoke target Lambda function')
        }

    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'text/html'},
        'body': html_content
    }

# Example usage (you wouldn't actually call this in your Lambda function)
if __name__ == "__main__":
    print(lambda_handler({}, {}))
