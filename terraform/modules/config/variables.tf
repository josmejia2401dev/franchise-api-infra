variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "credentials_secret_name" {
  description = "Secrets Manager secret name that stores the MongoDB credentials as JSON."
  type        = string
}

variable "mongodb_username" {
  description = "MongoDB username (sensitive)."
  type        = string
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB password (sensitive)."
  type        = string
  sensitive   = true
}
