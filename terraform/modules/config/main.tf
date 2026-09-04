# MongoDB credentials stored as a JSON secret in Secrets Manager. ECS resolves the
# individual keys (username/password) at container start and injects them as env vars.
resource "aws_secretsmanager_secret" "credentials" {
  name        = var.credentials_secret_name
  description = "MongoDB credentials for ${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    username = var.mongodb_username
    password = var.mongodb_password
  })
}
