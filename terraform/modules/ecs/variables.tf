variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region (used for the CloudWatch logs configuration)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet ids where the Fargate tasks run."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group id for the ECS tasks."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group the service registers into."
  type        = string
}

variable "image_uri" {
  description = "Full image URI (ECR repository URL plus tag) to deploy."
  type        = string
}

variable "uri_template" {
  description = "MongoDB URI template with {username}/{password} placeholders (non-secret env var)."
  type        = string
}

variable "credentials_secret_arn" {
  description = "ARN of the Secrets Manager JSON secret with username/password (resolved by ECS at container start)."
  type        = string
}

variable "container_port" {
  description = "Port the application listens on."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of running tasks."
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto scaling."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto scaling."
  type        = number
  default     = 2
}

variable "health_check_grace_period_seconds" {
  description = "Grace period before the load balancer health check can mark tasks unhealthy (allows slow app startup)."
  type        = number
  default     = 120
}

variable "cpu_target_utilization" {
  description = "Target average CPU utilization (percent) for auto scaling."
  type        = number
  default     = 70
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 14
}
