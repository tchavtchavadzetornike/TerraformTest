# Public URL of every application, keyed by its map id (app1, app2, ...).
# New apps appear here automatically — no edits required.
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
