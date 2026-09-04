# Franchise API — Infrastructure (Terraform + AWS)

Infrastructure as Code to deploy the Franchise API microservice on AWS using
**ECS Fargate + ECR + ALB + Secrets Manager**, with least-privilege IAM,
horizontal auto scaling and remote state (S3 + DynamoDB).

This is a **separate repository** from the application (`franchise-api`). The link
between them is the Docker image published to ECR, which CodeBuild builds directly
from the public application repo.

## Architecture

```
Internet -> ALB (public subnets, HTTP:80)
              -> ECS Service (Fargate, private subnets)
                   - Auto Scaling (target CPU)
                   - Task reads MongoDB config from SSM + Secrets Manager
                   - Outbound to MongoDB Atlas via NAT Gateway

CodeBuild -> clones public GitHub repo -> docker build -> push to ECR
```

## Layout

```
terraform/
├── bootstrap/            # Creates the S3 bucket + DynamoDB table for remote state (run once, first)
├── modules/
│   ├── network/          # VPC, public/private subnets, IGW, NAT, route tables
│   ├── ecr/              # ECR repository + lifecycle policy
│   ├── codebuild/        # CodeBuild project: clones the public repo, builds and pushes the image
│   ├── security/         # Security groups (ALB, ECS)
│   ├── iam/              # Execution role + task role (least privilege)
│   ├── secrets/          # Secrets Manager entry for MongoDB credentials
│   ├── alb/              # ALB, HTTP listener, target group (health check /actuator/health)
│   └── ecs/              # Cluster, task definition, service, auto scaling
└── environments/
    └── dev/
```

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with credentials (`aws configure`)
- A MongoDB Atlas cluster and its connection string

## Step 1 — Create the remote state backend (once)

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # set a globally-unique bucket name
terraform init
terraform apply
```

Note the outputs (`state_bucket_name`, `lock_table_name`).

## Step 2 — Point the environment backend to that bucket

In `terraform/environments/dev/backend.tf`, replace
`franchise-api-tfstate-<your-unique-suffix>` with the bucket name from Step 1.
(The DynamoDB table name matches the default `franchise-api-tf-lock`.)

## Step 3 — Deploy the environment

The MongoDB connection is split in two: a non-secret URL template stored in SSM
Parameter Store (with `{username}`/`{password}` placeholders) and the credentials
stored as a JSON secret in Secrets Manager. The application (profile `aws`) reads
both at start-up and assembles the final URI, so no full connection string or
credentials are ever hardcoded.

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars

# Provide the credentials as sensitive variables (do not commit them):
#   PowerShell:  $env:TF_VAR_mongodb_username = "your-user"
#                $env:TF_VAR_mongodb_password = "your-pass"
#   bash:        export TF_VAR_mongodb_username="your-user"
#                export TF_VAR_mongodb_password="your-pass"

terraform init
terraform apply
```

This creates the ECR repo, the CodeBuild project, the network, ALB and the ECS
service. The `github_repository_url` variable defaults to the public application
repo.

## Step 4 — Build and push the image with CodeBuild

CodeBuild clones the public repo, builds the Docker image and pushes it to ECR.
No manual `docker build` is needed.

```bash
aws codebuild start-build --project-name <codebuild_project_name>
```

Use the `codebuild_project_name` output for the project name. After the build
succeeds, ECS deploys the image (`latest` tag by default).

## Step 5 — Point Postman / clients to the ALB

Use the `api_base_url` output (e.g. `http://franchise-api-dev-alb-1234.us-east-1.elb.amazonaws.com`)
as the `baseUrl` variable in the Postman collection.

## Step 6 — Allow AWS to reach MongoDB Atlas

In the Atlas console (Network Access), allow the **NAT Gateway public IP** (or,
for a quick demo, `0.0.0.0/0`). Otherwise the tasks cannot connect to the cluster.

## IaC principles applied

- **Reproducibility**: every resource is declared as code; no manual console changes.
- **Idempotency**: repeated `apply` converges to the same state.
- **Versioning**: state is versioned in S3; the code lives in this repo.
- **Least privilege**: the execution role can read only the specific secret ARN.
- **No plaintext secrets**: MongoDB credentials live in Secrets Manager and are injected at runtime.

## Notes

- HTTP (port 80) is used on the ALB for simplicity. For production, add an HTTPS
  listener (443) with an ACM certificate and a domain.
- Run `terraform fmt` and `terraform validate` before your first apply.
