output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ec2_instance_id" {
  description = "ID of the app EC2 instance"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "Elastic IP attached to the app instance"
  value       = aws_eip.app.public_ip
}

output "github_actions_role_arn" {
  description = "Set this as the role-to-assume in the GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
}
