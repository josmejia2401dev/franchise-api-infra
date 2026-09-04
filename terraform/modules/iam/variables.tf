variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret the execution role is allowed to read (injected by ECS at start)."
  type        = string
}
