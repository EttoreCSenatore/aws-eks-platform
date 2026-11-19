terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  # Partial configuration: bucket and key come from backend.hcl
  # (terraform init -backend-config=backend.hcl), so no account IDs live in git.
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
