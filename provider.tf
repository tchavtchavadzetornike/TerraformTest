# Shared AWS provider definition.
#
# NOTE: Terraform only loads .tf files from the directory it is invoked in
# (it does NOT traverse parent directories). Because this project is deployed
# from within each `environments/<region>/` directory, an equivalent provider
# and terraform block is also declared inside each environment's `main.tf`.
# This root-level file documents the canonical provider configuration and is
# used if you ever run Terraform from the project root.

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
