provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

############################################
# VPC
############################################
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

############################################
# Security Groups
############################################
module "security_groups" {
  source = "../../modules/security-groups"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

############################################
# IAM
############################################
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  github_org   = var.github_org
  github_repo  = var.github_repo
}

############################################
# Compute
############################################
module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  instance_type         = var.instance_type
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  security_group_ids    = [module.security_groups.web_sg_id]
  instance_profile_name = module.iam.ec2_instance_profile_name
  key_pair_name         = var.key_pair_name
}
