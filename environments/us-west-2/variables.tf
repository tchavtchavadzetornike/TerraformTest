variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment name (used in tags and resource names)."
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming."
  type        = string
  default     = "ecs-nginx-demo"
}

# Map of applications to deploy. Each entry produces its own ALB + ECS service
# behind a shared VPC and ECS cluster. To add a new app (e.g. app3), just add a
# new entry here (or in terraform.tfvars) — no other changes are required.
#
# The map KEY is used for short resource names (e.g. "app3-alb"); `name` is the
# ECS service / task / container name. All other fields are optional and fall
# back to sensible defaults.
variable "applications" {
  description = "Applications to deploy, keyed by a short id (app1, app2, ...)."
  type = map(object({
    name               = string
    image              = optional(string, "nginx:latest")
    container_port     = optional(number, 80)
    cpu                = optional(number, 256)
    memory             = optional(number, 512)
    desired_count      = optional(number, 1)
    health_check_path  = optional(string, "/")
    log_retention_days = optional(number, 7)
  }))

  default = {
    app1 = { name = "nginx-app1" }
    app2 = { name = "nginx-app2" }
  }
}
