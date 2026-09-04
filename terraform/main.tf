locals {
  ecr_repository_name = var.project
  credentials_secret  = "${var.project}/${var.environment}/mongodb-credentials"
}

module "network" {
  source             = "./modules/network"
  project            = var.project
  environment        = var.environment
  availability_zones = var.availability_zones
}

module "ecr" {
  source          = "./modules/ecr"
  project         = var.project
  environment     = var.environment
  repository_name = local.ecr_repository_name
}

module "codebuild" {
  source                = "./modules/codebuild"
  project               = var.project
  environment           = var.environment
  aws_region            = var.aws_region
  github_repository_url = var.github_repository_url
  github_branch         = var.github_branch
  ecr_repository_url    = module.ecr.repository_url
  ecr_repository_arn    = module.ecr.repository_arn
  image_tag             = var.image_tag
}

module "security" {
  source      = "./modules/security"
  project     = var.project
  environment = var.environment
  vpc_id      = module.network.vpc_id
}

module "config" {
  source                  = "./modules/config"
  project                 = var.project
  environment             = var.environment
  credentials_secret_name = local.credentials_secret
  mongodb_username        = var.mongodb_username
  mongodb_password        = var.mongodb_password
}

module "iam" {
  source                 = "./modules/iam"
  project                = var.project
  environment            = var.environment
  credentials_secret_arn = module.config.credentials_secret_arn
}

module "alb" {
  source                = "./modules/alb"
  project               = var.project
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

module "ecs" {
  source                 = "./modules/ecs"
  project                = var.project
  environment            = var.environment
  aws_region             = var.aws_region
  private_subnet_ids     = module.network.private_subnet_ids
  ecs_security_group_id  = module.security.ecs_security_group_id
  execution_role_arn     = module.iam.execution_role_arn
  task_role_arn          = module.iam.task_role_arn
  target_group_arn       = module.alb.target_group_arn
  image_uri              = module.codebuild.image_uri
  uri_template           = var.mongodb_uri_template
  credentials_secret_arn = module.config.credentials_secret_arn
  desired_count          = var.desired_count
  min_capacity           = var.min_capacity
  max_capacity           = var.max_capacity
}
