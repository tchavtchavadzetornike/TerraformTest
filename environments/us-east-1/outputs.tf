
output "application_urls" {
  description = "Map of application id => public URL."
  value       = { for key, alb in module.alb : key => "http://${alb.alb_dns_name}" }
}

output "cluster_name" {
  description = "Name of the shared ECS cluster."
  value       = module.ecs_cluster.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.networking.vpc_id
}
