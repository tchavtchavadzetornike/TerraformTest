aws_region   = "us-west-2"
environment  = "staging"
project_name = "ecs-nginx-demo"

# Applications to deploy. To add another app, add one entry below — that's it.
# Only `name` is required; image/container_port/cpu/memory/desired_count are
# optional and default to nginx:latest / 80 / 256 / 512 / 1.
applications = {
  app1 = { name = "nginx-app1" }
  app2 = { name = "nginx-app2" }

  # app3 = { name = "nginx-app3" }
  # app4 = { name = "custom-app", image = "httpd:latest", cpu = 512, memory = 1024, desired_count = 2 }
}
