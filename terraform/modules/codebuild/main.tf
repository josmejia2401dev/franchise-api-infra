data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/codebuild/${var.project}-${var.environment}"
  retention_in_days = 14

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "build" {
  name = "${var.project}-${var.environment}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codebuild.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "build" {
  name = "${var.project}-${var.environment}-codebuild-policy"
  role = aws_iam_role.build.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.build.arn}:*"
      },
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_codebuild_project" "this" {
  name          = "${var.project}-${var.environment}-image-build"
  description   = "Clones ${var.github_repository_url} and builds/pushes the container image to ECR."
  service_role  = aws_iam_role.build.arn
  build_timeout = 20

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = var.ecr_repository_url
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = var.image_tag
    }
    environment_variable {
      name  = "GITHUB_REPOSITORY_URL"
      value = var.github_repository_url
    }
    environment_variable {
      name  = "GITHUB_BRANCH"
      value = var.github_branch
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = <<-BUILDSPEC
      version: 0.2
      phases:
        pre_build:
          commands:
            - git clone --depth 1 --branch "$GITHUB_BRANCH" "$GITHUB_REPOSITORY_URL" repo
            - aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
        build:
          commands:
            - docker build -t "$ECR_REPOSITORY_URL:$IMAGE_TAG" -f repo/deployment/Dockerfile repo
        post_build:
          commands:
            - docker push "$ECR_REPOSITORY_URL:$IMAGE_TAG"
    BUILDSPEC
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
