variable "project" {
  description = "Project name used for tagging and naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "github_repository_url" {
  description = "Public GitHub repository URL to clone and build."
  type        = string
}

variable "github_branch" {
  description = "Git branch to build."
  type        = string
  default     = "main"
}

variable "ecr_repository_url" {
  description = "ECR repository URL where the built image is pushed."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN used to scope push permissions."
  type        = string
}

variable "image_tag" {
  description = "Tag applied to the built image."
  type        = string
  default     = "latest"
}

variable "build_compute_type" {
  description = "CodeBuild compute type."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild managed image."
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "dockerhub_username" {
  description = "Docker Hub username used to authenticate pulls and avoid rate limits."
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub access token."
  type        = string
  sensitive   = true
}
