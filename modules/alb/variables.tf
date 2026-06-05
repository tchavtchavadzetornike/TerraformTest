variable "name" {
  description = "Name of the Application Load Balancer and its associated resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which the ALB and target group are created."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the internet-facing ALB is placed."
  type        = list(string)
}

variable "container_port" {
  description = "Port on which the backend containers listen and receive traffic."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used by the target group health check."
  type        = string
  default     = "/"
}
