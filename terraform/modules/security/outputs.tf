output "alb_security_group_id" {
  description = "Security group id for the ALB."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group id for the ECS tasks."
  value       = aws_security_group.ecs.id
}
