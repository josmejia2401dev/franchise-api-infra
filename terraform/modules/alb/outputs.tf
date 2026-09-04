output "alb_dns_name" {
  description = "Public DNS name of the ALB (used as the API base URL)."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group the ECS service registers into."
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}
