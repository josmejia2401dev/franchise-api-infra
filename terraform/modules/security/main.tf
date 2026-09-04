locals {
  name = "${var.project}-${var.environment}"
}

# Security group for the ALB: accepts HTTP from the internet.
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Allows inbound HTTP to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from allowed CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name}-alb-sg"
    Project     = var.project
    Environment = var.environment
  }
}

# Security group for the ECS tasks: only accepts traffic from the ALB SG.
resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs-sg"
  description = "Allows inbound from the ALB to the application container"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (to Atlas, Secrets Manager, ECR, logs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name}-ecs-sg"
    Project     = var.project
    Environment = var.environment
  }
}
