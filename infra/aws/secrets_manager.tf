resource "aws_secretsmanager_secret" "cognito_config" {
  name        = "cognito-config"
  description = "Cognito configuration for frontend"
}

// Not actual secrets, just using as middle-man
resource "aws_secretsmanager_secret_version" "cognito_config" {
  secret_id = aws_secretsmanager_secret.cognito_config.id
  secret_string = jsonencode({
    COGNITO_ENDPOINT     = "https://${aws_cognito_user_pool.cognito_pool.endpoint}"
    COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.cognito_pool_client.id
    COGNITO_REDIRECT_URI = "https://${var.s3_bucket_name}"
    COGNITO_DOMAIN       = "https://${aws_cognito_user_pool_domain.cognito_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
  })
}
