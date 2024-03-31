locals {
  public_subnets             = module.vpc.public_subnets
  vpc_id                     = module.vpc.vpc_id
  security_group_id          = aws_security_group.allow_http.id
  api_gateway_id             = aws_apigatewayv2_api.example.id
  api_gateway_url            = split("://", aws_apigatewayv2_api.example.api_endpoint)[1]
  api_gateway_domain_name    = aws_apigatewayv2_domain_name.example.domain_name_configuration[0].target_domain_name
  api_gateway_hosted_zone_id = aws_apigatewayv2_domain_name.example.domain_name_configuration[0].hosted_zone_id
  httpIntegrationId          = aws_apigatewayv2_integration.http.id
  lambdaIntegrationId        = aws_apigatewayv2_integration.lambda.id
  lambda2_name               = aws_lambda_function.lambda2.function_name
  s3_website                 = "http://${aws_s3_bucket_website_configuration.example.website_endpoint}/"
  lambda1_arn                = aws_lambda_function.lambda1.arn
}
