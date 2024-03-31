resource "aws_apigatewayv2_api" "example" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["*"]
    allow_origins = ["https://${var.domain_name}"]
  }
}

resource "aws_apigatewayv2_integration" "http" {
  api_id           = aws_apigatewayv2_api.example.id
  integration_type = "HTTP_PROXY"

  integration_method = "ANY"
  integration_uri    = local.s3_website
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.example.id
  integration_type = "AWS_PROXY"

  # integration_method = "GET"
  integration_uri = aws_lambda_function.lambda1.invoke_arn
}

resource "aws_apigatewayv2_route" "lambda" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
resource "aws_apigatewayv2_route" "http" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.example.id
  name        = "$default"
  auto_deploy = true
}
resource "aws_apigatewayv2_domain_name" "example" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.example.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  depends_on = [ aws_acm_certificate_validation.example ]
}
resource "aws_apigatewayv2_api_mapping" "example" {
  api_id      = aws_apigatewayv2_api.example.id
  domain_name = aws_apigatewayv2_domain_name.example.id
  stage       = aws_apigatewayv2_stage.default.id
}

# CORS for apigateway
 