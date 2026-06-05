terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS provider pinned to this environment's region. The default_tags block
# tags every resource created in this environment.
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

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Shared infrastructure (used by every application).
#
# The per-application resources (one ALB + one ECS service per app) live in
# applications.tf and are generated from the `var.applications` map.
# ---------------------------------------------------------------------------

# Networking: one shared VPC with public + private subnets.
module "networking" {
  source = "../../modules/networking"

  name_prefix = local.name_prefix
}

# ECS cluster: one shared cluster for all applications.
module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  cluster_name = "${local.name_prefix}-cluster"
}
