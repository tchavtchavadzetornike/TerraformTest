terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


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


module "networking" {
  source = "../../modules/networking"

  name_prefix = local.name_prefix
}

module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  cluster_name = "${local.name_prefix}-cluster"
}
