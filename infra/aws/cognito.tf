resource "random_id" "cognito_domain_prefix" {
  byte_length = 8
}

resource "aws_cognito_user_pool" "cognito_pool" {
  name = "spa-app-pool"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false #true
    required                 = true
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_symbols   = true
  }

  auto_verified_attributes = ["email"]
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
}

// FOR GOOGLE: JS Origins - [Cognito Domain], redirect URIs - [Cognito Domain] + /oauth2/idpresponse.
// might take a couple minutes

resource "aws_cognito_user_pool_client" "cognito_pool_client" {
  name                                 = "nextapp-cognito-client"
  user_pool_id                         = aws_cognito_user_pool.cognito_pool.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  callback_urls = [
    "https://brutus.ettukube.com",
    "http://localhost:3000"
  ]
  supported_identity_providers = ["COGNITO", "Google"]

  # write_attributes = ["email"]
  depends_on = [aws_cognito_identity_provider.google_provider]
}

resource "aws_cognito_identity_provider" "google_provider" {
  user_pool_id  = aws_cognito_user_pool.cognito_pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email"
    client_id        = var.google_auth_client_id
    client_secret    = var.google_auth_client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "sub" # for stability use "sub"
  }
}

resource "aws_cognito_user_pool_domain" "cognito_pool_domain" {
  domain                = random_id.cognito_domain_prefix.hex
  user_pool_id          = aws_cognito_user_pool.cognito_pool.id
  managed_login_version = 2 # Managed UI
}

resource "aws_cognito_managed_login_branding" "cognito_pool_ui" {
  client_id    = aws_cognito_user_pool_client.cognito_pool_client.id
  user_pool_id = aws_cognito_user_pool.cognito_pool.id

  use_cognito_provided_values = true
}
