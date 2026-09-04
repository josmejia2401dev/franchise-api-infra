output "vpc_id" {
  description = "VPC id."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Ids of the public subnets (ALB)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Ids of the private subnets (ECS tasks)."
  value       = aws_subnet.private[*].id
}
