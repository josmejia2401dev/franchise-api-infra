variable "aws_region" {
  description = "AWS region where the remote state resources are created."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used for tagging."
  type        = string
  default     = "franchise-api"
}

variable "state_bucket_name" {
  description = "Globally unique name for the S3 bucket that stores the Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "Name for the DynamoDB table used for state locking."
  type        = string
  default     = "franchise-api-tf-lock"
}
