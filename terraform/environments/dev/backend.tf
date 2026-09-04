terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 with DynamoDB locking. The bucket and table are created
  # first by the bootstrap configuration. Values below must match that output.
  backend "s3" {
    bucket         = "franchise-api-tfstate-<your-unique-suffix>"
    key            = "franchise-api/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "franchise-api-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
