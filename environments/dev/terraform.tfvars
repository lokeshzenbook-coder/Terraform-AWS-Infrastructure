aws_region   = "us-east-1"
project_name = "myapp"
environment  = "dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

instance_type     = "t3.nano"
key_pair_name     = null
allowed_ssh_cidrs = ["203.0.113.0/24"]

github_org  = "lokeshzenbook-coder"
github_repo = "Terraform-AWS-Infrastructure"
