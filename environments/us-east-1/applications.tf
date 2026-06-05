

module "alb" {
  source   = "../../modules/alb"
  for_each = var.applications

  name              = "${each.key}-alb"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = each.value.container_port
  health_check_path = each.value.health_check_path
}


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
  log_retention_days    = each.value.log_retention_days

  depends_on = [module.alb]
}
