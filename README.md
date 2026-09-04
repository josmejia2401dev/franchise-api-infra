# Franchise API — Infrastructure (Terraform + AWS)

Infrastructure as Code to deploy the Franchise API microservice on AWS using
**ECS Fargate + ECR + ALB + Secrets Manager**, with least-privilege IAM,
horizontal auto scaling, remote state (S3 + DynamoDB) and multiple environments
(dev / staging / prod).

This is a **separate repository** from the application (`franchise-api`). The link
between them is the Docker image published to ECR.

## Architecture

```
Internet -> ALB (public subnets, HTTP:80)
              -> ECS Service (Fargate, private subnets)
                   - Auto Scaling (target CPU)
                   - Task reads MONGODB_URI from Secrets Manager
                   - Outbound to MongoDB Atlas via NAT Gateway
```

## Layout

```
terraform/
├── bootstrap/            # Creates the S3 bucket + DynamoDB table for remote state (run once, first)
├── modules/
│   ├── network/          # VPC, public/private subnets, IGW, NAT, route tables
│   ├── ecr/              # ECR repository + lifecycle policy
│   ├── security/         # Security groups (ALB, ECS)
│   ├── iam/              # Execution role + task role (least privilege)
│   ├── secrets/          # Secrets Manager entry for MONGODB_URI
│   ├── alb/              # ALB, HTTP listener, target group (health check /actuator/health)
│   └── ecs/              # Cluster, task definition, service, auto scaling
└── environments/
    ├── dev/
    ├── staging/
    └── prod/
```

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with credentials (`aws configure`)
- Docker (to build and push the image)
- A MongoDB Atlas cluster and its connection string

## Step 1 — Create the remote state backend (once)

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # set a globally-unique bucket name
terraform init
terraform apply
```

Note the outputs (`state_bucket_name`, `lock_table_name`).

## Step 2 — Point each environment backend to that bucket

In `terraform/environments/<env>/backend.tf`, replace
`franchise-api-tfstate-<your-unique-suffix>` with the bucket name from Step 1.
(The DynamoDB table name matches the default `franchise-api-tf-lock`.)

## Step 3 — Create the ECR repository first (needed before pushing the image)

The ECR repo is part of the environment stack, but you need it to exist before
you can push an image. Apply only the ECR module target first:

```bash
cd terraform/environments/dev
terraform init
terraform apply -target=module.ecr
```

Grab the `ecr_repository_url` output.

## Step 4 — Build and push the Docker image

From the application repo (`franchise-api`), build the image and push it to ECR:

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build (from the franchise-api repo root; the Dockerfile is under deployment/)
docker build -t franchise-api -f deployment/Dockerfile .

# Tag and push
docker tag franchise-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/franchise-api:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/franchise-api:latest
```

## Step 5 — Deploy the full environment

The MongoDB connection is split in two: a non-secret URL template stored in SSM
Parameter Store (with `{username}`/`{password}` placeholders) and the credentials
stored as a JSON secret in Secrets Manager. The application (profile `aws`) reads
both at start-up and assembles the final URI, so no full connection string or
credentials are ever hardcoded.

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # set image_uri (and the template if your cluster differs)

# Provide the credentials as sensitive variables (do not commit them):
#   PowerShell:  $env:TF_VAR_mongodb_username = "your-user"
#                $env:TF_VAR_mongodb_password = "your-pass"
#   bash:        export TF_VAR_mongodb_username="your-user"
#                export TF_VAR_mongodb_password="your-pass"

terraform apply
```

The ECS task receives, as plain environment variables, only the **names** of the
SSM parameter and the secret (not their values) plus `SPRING_PROFILES_ACTIVE=aws`.
The values are read at runtime by the task role (least privilege).

When it finishes, the `api_base_url` output is the public URL of the API.

## Step 6 — Point Postman / clients to the ALB

Use the `api_base_url` output (e.g. `http://franchise-api-dev-alb-1234.us-east-1.elb.amazonaws.com`)
as the `baseUrl` variable in the Postman collection.

## Step 7 — Allow AWS to reach MongoDB Atlas

In the Atlas console (Network Access), allow the **NAT Gateway public IP** (or,
for a quick demo, `0.0.0.0/0`). Otherwise the tasks cannot connect to the cluster.

## Environments

Each environment is applied independently from its own folder, with its own
remote state key (`franchise-api/<env>/terraform.tfstate`) and its own sizing.
Repeat Steps 3–6 in `environments/staging` or `environments/prod` as needed.

## IaC principles applied

- **Reproducibility**: every resource is declared as code; no manual console changes.
- **Idempotency**: repeated `apply` converges to the same state.
- **Versioning**: state is versioned in S3; the code lives in this repo.
- **Least privilege**: the execution role can read only the specific secret ARN.
- **No plaintext secrets**: `MONGODB_URI` lives in Secrets Manager and is injected at runtime.

## Notes

- HTTP (port 80) is used on the ALB for simplicity. For production, add an HTTPS
  listener (443) with an ACM certificate and a domain.
- `terraform fmt` and `terraform validate` were not run in the authoring
  environment (Terraform not installed there); run them before your first apply.
