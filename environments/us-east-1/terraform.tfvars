aws_region   = "us-east-1"
environment  = "dev"
project_name = "ecs-nginx-demo"

applications = {
  app1 = { name = "nginx-app1" }
  app2 = { name = "nginx-app2" }

}
