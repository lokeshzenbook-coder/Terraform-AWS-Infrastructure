output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ec2_instance_id" {
  description = "ID of the app EC2 instance"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "Elastic IP attached to the app instance"
  value       = module.compute.public_ip
}

output "github_actions_role_arn" {
  description = "Set this as the role-to-assume in the GitHub Actions workflow"
  value       = module.iam.github_actions_role_arn
}
