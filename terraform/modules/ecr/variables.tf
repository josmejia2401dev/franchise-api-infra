variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "image_retention_count" {
  description = "Number of most-recent images to keep; older ones are expired."
  type        = number
  default     = 10
}
