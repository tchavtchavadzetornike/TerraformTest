# ===========================================================================
# Per-application resources, generated from var.applications.
#
# Every entry in the map gets:
#   - its own internet-facing ALB (module.alb["<key>"])
#   - its own ECS Fargate service  (module.service["<key>"])
#
# Adding a new application is a ONE-LINE change in terraform.tfvars, e.g.:
#   applications = {
#     app1 = { name = "nginx-app1" }
#     app2 = { name = "nginx-app2" }
#     app3 = { name = "nginx-app3" }   # <-- add this
#   }
# No changes to this file (or any module) are needed.
# ===========================================================================

# One ALB per application.
module "alb" {
  source   = "../../modules/alb"
  for_each = var.applications

  name              = "${each.key}-alb"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = each.value.container_port
}

# One ECS service per application, each behind its paired ALB.
# depends_on ensures the ALB (listener + target group) exists before the
# service tries to register targets, avoiding a race condition.
module "service" {
  source   = "../../modules/ecs_service"
  for_each = var.applications

  service_name          = each.value.name
  aws_region            = var.aws_region
  cluster_id            = module.ecs_cluster.cluster_id
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.alb[each.key].alb_security_group_id
  target_group_arn      = module.alb[each.key].target_group_arn
  container_image       = each.value.image
  container_port        = each.value.container_port
  cpu                   = each.value.cpu
  memory                = each.value.memory
  desired_count         = each.value.desired_count

  depends_on = [module.alb]
}
