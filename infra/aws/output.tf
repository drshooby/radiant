output "spa_uri" {
  value = aws_s3_bucket_website_configuration.cloud_final_bucket.website_endpoint
}

// For app

output "cognito_pool_client_id" {
  value = aws_cognito_user_pool_client.cognito_pool_client.id
}

output "cognito_pool_domain" {
  value = "https://${aws_cognito_user_pool_domain.cognito_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "cognito_pool_endpoint" {
  value = "https://${aws_cognito_user_pool.cognito_pool.endpoint}"
}

output "cognito_config_api_url" {
  value       = aws_api_gateway_resource.cognito.path
  description = "URL to fetch Cognito configuration"
}

output "api_gateway_identifier" {
  value = aws_api_gateway_stage.cognito_stage.invoke_url
}
