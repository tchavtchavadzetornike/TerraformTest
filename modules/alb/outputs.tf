output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group that ECS tasks register with."
  value       = aws_lb_target_group.this.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group (used to allow traffic to ECS tasks)."
  value       = aws_security_group.alb.id
}

output "listener_arn" {
  description = "ARN of the HTTP listener (used for service dependency ordering)."
  value       = aws_lb_listener.http.arn
}
