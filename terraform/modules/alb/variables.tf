variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC id."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ids where the ALB is placed."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group id for the ALB."
  type        = string
}

variable "container_port" {
  description = "Port the target group forwards traffic to."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path used by the ALB health check."
  type        = string
  default     = "/actuator/health/liveness"
}
