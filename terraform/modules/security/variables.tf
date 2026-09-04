variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC id where the security groups are created."
  type        = string
}

variable "container_port" {
  description = "Port the application listens on inside the container."
  type        = number
  default     = 8080
}

variable "alb_ingress_cidr" {
  description = "CIDR allowed to reach the ALB (0.0.0.0/0 for public access)."
  type        = string
  default     = "0.0.0.0/0"
}
