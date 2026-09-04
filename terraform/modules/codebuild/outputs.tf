output "project_name" {
  description = "CodeBuild project name. Trigger a build with: aws codebuild start-build --project-name <name>"
  value       = aws_codebuild_project.this.name
}

output "image_uri" {
  description = "Full image URI produced by the build (ECR repo URL + tag)."
  value       = "${var.ecr_repository_url}:${var.image_tag}"
}

output "log_group_name" {
  description = "CloudWatch log group for build logs."
  value       = aws_cloudwatch_log_group.build.name
}
