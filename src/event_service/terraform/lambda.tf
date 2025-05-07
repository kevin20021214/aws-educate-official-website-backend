######################################
# terraform/lambda.tf
######################################

# 1. Data sources for ECR auth and account info

data "aws_ecr_authorization_token" "token" {}

data "aws_caller_identity" "this" {}

# 2. Docker provider for building and pushing image to ECR

provider "docker" {
  # Uses default Docker host or DOCKER_HOST env var
  registry_auth {
    address  = format("%s.dkr.ecr.%s.amazonaws.com", data.aws_caller_identity.this.account_id, var.aws_region)
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

# 3. DynamoDB Table to store events

resource "aws_dynamodb_table" "events" {
  name         = local.event_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Service     = var.service_underscore
  }
}

# 4. Unique suffix for naming

resource "random_string" "suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# 5. Locals for paths and names

locals {
  source_path       = "${path.module}/.."
  lambda_path       = "${local.source_path}/test"
  lambda_files      = fileset(local.lambda_path, "**")
  dir_sha           = sha1(join("", [for f in local.lambda_files : filesha1("${local.lambda_path}/${f}")]))
  create_event_name = "${var.environment}-${var.service_underscore}-create-event-${random_string.suffix.result}"
}

# 6. Build & push Docker image to ECR

resource "docker_image" "create_event_image" {
  name = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.create_event_name}:latest"

  build {
    context    = local.lambda_path
    dockerfile = "Dockerfile"
    platform   = "linux/amd64"
  }
}

resource "docker_registry_image" "create_event_image_pushed" {
  name = docker_image.create_event_image.name
}

# 7. IAM role for Lambda

resource "aws_iam_role" "lambda_role" {
  name = "${local.create_event_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# 新增一条最小权限 Policy：只允许往指定表写入
resource "aws_iam_policy" "lambda_dynamodb_put" {
  name        = "${local.create_event_name}-dynamo-write"
  description = "Allow Lambda to PutItem into ${local.event_table_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"  # 如果后续需要修改也可以加
      ]
      Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.this.account_id}:table/${local.event_table_name}"
    }]
  })
}

# 把这条策略附加到 Lambda 执行角色
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_write" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_put.arn
}

# 8. Lambda Function (container image)

resource "aws_lambda_function" "create_event" {
  function_name = local.create_event_name
  package_type  = "Image"
  image_uri     = docker_registry_image.create_event_image_pushed.name
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  publish       = false

  environment {
    variables = {
      ENVIRONMENT = var.environment
      SERVICE     = var.service_underscore
      EVENT_TABLE = local.event_table_name
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
}

# 9. API Gateway: POST /event

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.service_hyphen}-api"
  description = "API for ${var.service_hyphen}"
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Service     = var.service_underscore
  }
}

resource "aws_api_gateway_resource" "event" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "event"
}

resource "aws_api_gateway_method" "post_event" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.event.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_event_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.event.id
  http_method             = aws_api_gateway_method.post_event.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_event.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.post_event_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment
}

# 10. Output endpoint URL

output "post_event_url" {
  description = "Invoke URL for POST /event"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.deployment.stage_name}/event"
}
