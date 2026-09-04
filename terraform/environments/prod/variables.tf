variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "franchise-api"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "availability_zones" {
  description = "Availability zones for the subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "image_uri" {
  description = "Full image URI (ECR repo URL + tag) to deploy."
  type        = string
}

variable "mongodb_uri_template" {
  description = "MongoDB URI template with {username}/{password} placeholders (non-secret)."
  type        = string
  default     = "mongodb+srv://{username}:{password}@cluster0.w5f4gxm.mongodb.net/franchise?retryWrites=true&w=majority&appName=Cluster0"
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

variable "desired_count" {
  description = "Initial number of running tasks."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum tasks for auto scaling."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum tasks for auto scaling."
  type        = number
  default     = 6
}
