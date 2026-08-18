variable "project_name" {
  description = "Project name, used as a resource name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID to launch the instance in"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the instance"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = null
}
