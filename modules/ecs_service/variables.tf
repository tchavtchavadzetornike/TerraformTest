variable "service_name" {
  description = "Name of the ECS service, task family, and container."
  type        = string
}

variable "aws_region" {
  description = "AWS region (used to configure the CloudWatch Logs driver)."
  type        = string
}

variable "cluster_id" {
  description = "ID/ARN of the ECS cluster the service runs in."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which the ECS task security group is created."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where the Fargate tasks run."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the paired ALB; tasks only accept traffic from it."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group the service registers tasks with."
  type        = string
}

variable "container_image" {
  description = "Container image to run."
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "cpu" {
  description = "CPU units for the task (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MiB) for the task."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of task copies to run."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Retention period (in days) for the CloudWatch log group."
  type        = number
  default     = 7
}
