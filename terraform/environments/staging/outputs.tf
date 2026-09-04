output "api_base_url" {
  description = "Public base URL of the API (ALB DNS)."
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL to push the image to."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "log_group_name" {
  description = "CloudWatch log group for the application."
  value       = module.ecs.log_group_name
}
