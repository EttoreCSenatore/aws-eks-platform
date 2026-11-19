variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "eks-platform"
}

variable "region" {
  description = "AWS region for the state bucket and IAM roles."
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the CI roles, as owner/name."
  type        = string
  default     = "EttoreCSenatore/aws-eks-platform"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "Use the form owner/name."
  }
}

variable "apply_environment" {
  description = "GitHub Actions environment whose jobs may assume the apply role. Protect it with required reviewers."
  type        = string
  default     = "production"
}
