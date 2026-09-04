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
  default     = "dev"
}

variable "availability_zones" {
  description = "Availability zones for the subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "github_repository_url" {
  description = "Public GitHub repository cloned and built by CodeBuild."
  type        = string
  default     = "https://github.com/josmejia2401dev/franchise-api"
}

variable "github_branch" {
  description = "Branch built by CodeBuild."
  type        = string
  default     = "main"
}

variable "image_tag" {
  description = "Tag applied to the built image and deployed by ECS."
  type        = string
  default     = "latest"
}

variable "mongodb_uri_template" {
  description = "MongoDB URI template with {username}/{password} placeholders (non-secret: host, database, options)."
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
  default     = 1
}

variable "min_capacity" {
  description = "Minimum tasks for auto scaling."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum tasks for auto scaling."
  type        = number
  default     = 2
}

variable "dockerhub_username" {
  description = "Docker Hub username used by CodeBuild to authenticate and avoid pull rate limits."
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub access token used by CodeBuild."
  type        = string
  sensitive   = true
}
