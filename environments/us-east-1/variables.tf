variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (used in tags and resource names)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming."
  type        = string
  default     = "ecs-nginx-demo"
}

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
