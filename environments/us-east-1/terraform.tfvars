aws_region   = "us-east-1"
environment  = "dev"
project_name = "ecs-nginx-demo"

applications = {
  app1 = { name = "nginx-app1" }
  app2 = { name = "nginx-app2" , container_port=4040 , memory=256}

}
