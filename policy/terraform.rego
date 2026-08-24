package terraform.policy

import future.keywords.in

# Deny if any S3 bucket lacks encryption
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.server_side_encryption_configuration
  msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [resource.address])
}

# Deny security groups that open SSH (22) to the world
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group"
  rule := resource.change.after.ingress[_]
  rule.from_port == 22
  "0.0.0.0/0" in rule.cidr_blocks
  msg := sprintf("Security group '%s' allows unrestricted SSH access (0.0.0.0/0)", [resource.address])
}

# Deny EC2 instances without IMDSv2 enforced
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  resource.change.after.metadata_options[0].http_tokens != "required"
  msg := sprintf("EC2 instance '%s' must enforce IMDSv2 (http_tokens = required)", [resource.address])
}

# Deny unencrypted EBS volumes
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  not resource.change.after.root_block_device[0].encrypted
  msg := sprintf("EC2 instance '%s' root volume must be encrypted", [resource.address])
}
