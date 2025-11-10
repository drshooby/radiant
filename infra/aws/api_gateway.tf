# API Gateway REST API
resource "aws_api_gateway_rest_api" "cognito_api" {
  name        = "cognito-config-api"
  description = "API for Cognito configuration"
}

# /api resource
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  parent_id   = aws_api_gateway_rest_api.cognito_api.root_resource_id
  path_part   = "api"
}

# /api/cognito resource
resource "aws_api_gateway_resource" "cognito" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "cognito"
}

# GET method
resource "aws_api_gateway_method" "cognito_get" {
  rest_api_id   = aws_api_gateway_rest_api.cognito_api.id
  resource_id   = aws_api_gateway_resource.cognito.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda integration
resource "aws_api_gateway_integration" "cognito_lambda" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  resource_id = aws_api_gateway_resource.cognito.id
  http_method = aws_api_gateway_method.cognito_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cognito_func.invoke_arn
}

# OPTIONS method for CORS preflight
resource "aws_api_gateway_method" "cognito_options" {
  rest_api_id   = aws_api_gateway_rest_api.cognito_api.id
  resource_id   = aws_api_gateway_resource.cognito.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Mock integration for OPTIONS
resource "aws_api_gateway_integration" "cognito_options" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  resource_id = aws_api_gateway_resource.cognito.id
  http_method = aws_api_gateway_method.cognito_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# OPTIONS method response
resource "aws_api_gateway_method_response" "cognito_options" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  resource_id = aws_api_gateway_resource.cognito.id
  http_method = aws_api_gateway_method.cognito_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# OPTIONS integration response
resource "aws_api_gateway_integration_response" "cognito_options" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  resource_id = aws_api_gateway_resource.cognito.id
  http_method = aws_api_gateway_method.cognito_options.http_method
  status_code = aws_api_gateway_method_response.cognito_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'" # update this
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cognito_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "cognito_api" {
  depends_on = [
    aws_api_gateway_integration.cognito_lambda,
    aws_api_gateway_integration.cognito_options
  ]

  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
}

resource "aws_api_gateway_stage" "cognito_stage" {
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.cognito_api.id
  rest_api_id   = aws_api_gateway_rest_api.cognito_api.id
}

