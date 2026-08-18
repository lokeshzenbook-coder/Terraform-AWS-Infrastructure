variable "project_name" {
  description = "Project name, used as a resource name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_org" {
  description = "GitHub organization/user that owns the repo (for OIDC trust policy)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (for OIDC trust policy)"
  type        = string
}
