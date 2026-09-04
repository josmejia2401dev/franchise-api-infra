locals {
  name = "${var.project}-${var.environment}"
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ── Execution role ─────────────────────────────────────────────────────────
# Used by the ECS agent to pull the image, write logs, and resolve the secret
# that is injected into the container as environment variables at start-up.
resource "aws_iam_role" "execution" {
  name               = "${local.name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Least-privilege: allow reading ONLY the specific credentials secret ARN.
data "aws_iam_policy_document" "read_secret" {
  statement {
    sid       = "ReadMongoCredentialsSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.credentials_secret_arn]
  }
}

resource "aws_iam_role_policy" "execution_secret" {
  name   = "${local.name}-read-secret"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secret.json
}

# ── Task role ──────────────────────────────────────────────────────────────
# Assumed by the application at runtime. Empty because the app only talks to
# MongoDB Atlas (external) and reads its config from injected env vars.
resource "aws_iam_role" "task" {
  name               = "${local.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
