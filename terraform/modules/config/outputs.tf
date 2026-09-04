output "credentials_secret_arn" {
  description = "ARN of the credentials secret (granted to the execution role and referenced by the task definition)."
  value       = aws_secretsmanager_secret.credentials.arn
}
