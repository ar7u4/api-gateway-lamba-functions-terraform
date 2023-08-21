provider "aws" {
  region = var.aws_region
}

resource "aws_lambda_function" "example_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "example-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_api_gateway_rest_api" "example_api" {
  name        = "example-api"
  description = "Example API created with Terraform"
}

resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "mock"
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.example_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "example_method_response" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "example_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = jsonencode({
      message = "Lambda response from Terraform-created API"
    })
  }
}

resource "aws_api_gateway_deployment" "example_deployment" {
  depends_on = [
    aws_api_gateway_integration.example_integration_response,
    aws_api_gateway_method_response.example_method_response
  ]

  rest_api_id = aws_api_gateway_rest_api.example_api.id
  stage_name  = "dev"
}
