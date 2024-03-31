data "archive_file" "lambda1" {
  type        = "zip"
  source_file = "../python/lambda1.py"
  output_path = "lambda1.zip"
}
data "archive_file" "lambda2" {
  type        = "zip"
  source_file = "../python/lambda2.py"
  output_path = "lambda2.zip"
}
data "archive_file" "lambda3" {
  type        = "zip"
  source_file = "../python/lambda3.py"
  output_path = "lambda3.zip"
}

resource "aws_lambda_function" "lambda1" {
  filename      = "lambda1.zip"
  function_name = var.lambda1_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda1.lambda_handler"

  source_code_hash = data.archive_file.lambda1.output_base64sha256

  runtime = "python3.12"
  timeout = 10

  environment {
    variables = {
      API_GATEWAY_ID      = local.api_gateway_id
      HTTP_INTEGRATION_ID = local.httpIntegrationId
      S3_WEBSITE          = local.s3_website
      LAMBDA2_NAME        = local.lambda2_name
    }
  }
}
resource "aws_lambda_function" "lambda2" {
  filename      = "lambda2.zip"
  function_name = var.lambda2_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda2.lambda_handler"

  source_code_hash = data.archive_file.lambda2.output_base64sha256

  runtime = "python3.12"
  timeout = 20

  environment {
    variables = {
      API_GATEWAY_ID      = local.api_gateway_id
      ECS_CLUSTER         = var.cluster_name
      ECS_TASK_DEFINITION = var.task_definition_name
      HTTP_INTEGRATION_ID = local.httpIntegrationId
    }
  }
}

resource "aws_lambda_function" "lambda3" {
  filename      = "lambda3.zip"
  function_name = var.lambda3_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda3.lambda_handler"

  source_code_hash = data.archive_file.lambda3.output_base64sha256

  runtime = "python3.12"
  timeout = 20
  environment {
    variables = {
      API_GATEWAY_ID        = local.api_gateway_id
      ECS_CLUSTER           = var.cluster_name
      LAMBDA_INTEGRATION_ID = local.lambdaIntegrationId
      HTTP_INTEGRATION_ID   = local.httpIntegrationId
      S3_WEBSITE            = local.s3_website
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "iam_for_lambda" {
  name                = "${var.cluster_name}-lambda-role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSLambdaExecute"]
  inline_policy {
    name = "inline_policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "lambda:InvokeFunction"
          ],
          Resource = "arn:aws:lambda:*:*:function:${var.lambda2_name}"
        },
        {
          Effect = "Allow",
          Action = [
            "apigateway:GET",
            "apigateway:PATCH",
            "apigateway:POST",
            "apigateway:DELETE"
          ],
          Resource = [
            "arn:aws:apigateway:*::/apis/${local.api_gateway_id}/integrations",
            "arn:aws:apigateway:*::/apis/${local.api_gateway_id}/routes",
            "arn:aws:apigateway:*::/apis/${local.api_gateway_id}/integrations/*",
            "arn:aws:apigateway:*::/apis/${local.api_gateway_id}/routes/*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "ecs:RunTask",
            "ecs:DescribeTasks",
            "ecs:ListTasks",
            "ecs:StopTask"
          ],
          Resource = "*"
        },
        {
          Effect   = "Allow",
          Action   = "ec2:DescribeNetworkInterfaces",
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda1.function_name
  principal     = "apigateway.amazonaws.com"
  # The source_arn specifies which API Gateway and route can invoke the Lambda. Adjust the ARN accordingly.
  source_arn = "${aws_apigatewayv2_api.example.execution_arn}/*/*"
}


##Alarm for lambda 3 
## If last 5 min there is no connection , then alarm will be triggered , which will triger lambda3

resource "aws_cloudwatch_metric_alarm" "count" {
  alarm_name          = "${var.lambda3_name}_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  ok_actions          = [aws_lambda_function.lambda3.arn]
  dimensions = {
    ApiId = local.api_gateway_id
    Stage = "$default"
  }
}

resource "aws_lambda_permission" "allow_alarm" {
  statement_id  = "AllowExecutionFromAlarm"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda3.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.count.arn
}