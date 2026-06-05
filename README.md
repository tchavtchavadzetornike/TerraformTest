# Terraform ECS Fargate — Dual Nginx Apps

This project deploys **two Nginx welcome-page applications** on **AWS ECS Fargate**,
each fronted by its own **Application Load Balancer (ALB)**. Both applications share a
single VPC and a single ECS cluster. The project uses a **modular structure** and a
**region-based environment separation** (each region is its own deployable workspace
under `environments/`).

## Architecture

```
                 Internet
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
   app1-alb (ALB)          app2-alb (ALB)      ← internet-facing, public subnets
        │                       │
        ▼                       ▼
   target group (ip)       target group (ip)
        │                       │
        ▼                       ▼
   nginx-app1 task         nginx-app2 task      ← Fargate, private subnets
        └───────────┬───────────┘
                    ▼
          Shared ECS Cluster (FARGATE / FARGATE_SPOT)
                    │
          Shared VPC (10.0.0.0/16)
            ├── 2 public subnets  (ALBs + NAT GW)
            └── 2 private subnets (ECS tasks, egress via single NAT GW)
```

Each ECS task only accepts inbound traffic from its paired ALB security group
(least-privilege). Tasks run in private subnets with `assign_public_ip = false`
and reach the internet (e.g. to pull the Nginx image) through a single NAT Gateway.

## Project layout

```
.
├── environments/
│   ├── us-east-1/   # environment "dev"     (region us-east-1)
│   │   ├── main.tf          # shared infra: networking + ECS cluster
│   │   ├── applications.tf  # per-app ALB + ECS service (for_each over the apps map)
│   │   ├── variables.tf     # incl. the `applications` map
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars # where you list the apps to deploy
│   │   └── backend.tf       # S3 remote state (partial config)
│   └── us-west-2/   # environment "staging" (region us-west-2) — same files
├── modules/
│   ├── networking/  # VPC, subnets, IGW, NAT GW, route tables
│   ├── ecs_cluster/ # shared ECS cluster + capacity providers
│   ├── alb/         # ALB, SG, listener, target group
│   └── ecs_service/ # IAM role, log group, task definition, ECS service, task SG
├── provider.tf      # canonical provider definition (reference)
├── versions.tf      # canonical version constraints (reference)
└── README.md
```

> **Note on `provider.tf` / `versions.tf` at the root:** Terraform only loads `.tf`
> files from the directory it is invoked in (it does not read parent directories).
> Because you deploy from inside an `environments/<region>/` directory, the same
> `terraform`/`provider` blocks are declared inside each environment's `main.tf`.
> The root files document the canonical configuration.

## Prerequisites

- **Terraform** `>= 1.5.0`
- **AWS CLI** installed and configured with credentials
  (`aws configure`, or environment variables, or an SSO/role profile).
  Verify with: `aws sts get-caller-identity`
- **AWS provider** `~> 5.0` (installed automatically by `terraform init`)
- **IAM permissions** for the principal running Terraform, sufficient to manage:
  - EC2 / VPC: VPCs, subnets, route tables, internet gateway, NAT gateway, EIPs,
    security groups
  - Elastic Load Balancing: load balancers, listeners, target groups
  - ECS: clusters, services, task definitions
  - IAM: create roles, attach policies, pass role (`iam:PassRole`)
  - CloudWatch Logs: create log groups
  - Application Auto Scaling / Container Insights (CloudWatch)

  For a quick start you can use a broad managed policy such as `AdministratorAccess`,
  but a scoped policy covering the services above is recommended for production.

## Deploy (locally)

Each region is deployed independently from its own directory. Pick the region you want
and run Terraform there. Prefer CI? See
[Deploy with GitHub Actions](#deploy-with-github-actions-oidc--remote-state).

> The environments use an **S3 remote backend** (`backend.tf`), so `terraform init`
> needs the backend config passed via `-backend-config`. Create the state bucket and
> lock table first (see [step 1 of the CI setup](#1-create-the-remote-state-backend-one-time-per-aws-account)).

```bash
# 1. Move into the chosen environment
cd environments/us-east-1   # or environments/us-west-2

# 2. Initialize providers, modules and the S3 backend
terraform init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="key=ecs-nginx/us-east-1/terraform.tfstate" \
  -backend-config="region=<state-bucket-region>" \
  -backend-config="dynamodb_table=<your-lock-table>" \
  -backend-config="encrypt=true"

# 3. (optional) Review the formatting and validate
terraform fmt -recursive
terraform validate

# 4. Preview the changes
terraform plan

# 5. Apply (creates ~30 resources; takes a few minutes,
#    mostly waiting on the ALB and NAT Gateway)
terraform apply
```

The variable values come from `terraform.tfvars` in each environment directory, so no
extra flags are required.

## Accessing the applications

After `apply` completes, Terraform prints the outputs. The app URLs are exposed as a
single `application_urls` map keyed by app id, so every app (including ones you add
later) appears automatically:

```bash
terraform output application_urls
# {
#   "app1" = "http://app1-alb-123456.us-east-1.elb.amazonaws.com"
#   "app2" = "http://app2-alb-789012.us-east-1.elb.amazonaws.com"
# }

# A single app's URL:
terraform output -raw 'application_urls["app1"]'
```

Open the printed URLs in a browser (or `curl` them):

```bash
curl "$(terraform output -raw 'application_urls["app1"]')"
```

Each should return the default **"Welcome to nginx!"** page. It may take a minute or
two after `apply` for the ECS tasks to start and pass ALB health checks before the
URLs respond.

## Adding another application (app3, app4, ...)

Apps are data-driven: each environment renders one ALB + one ECS service per entry in
the `applications` map (see `environments/<region>/applications.tf`). To add an app,
add **one line** to that environment's `terraform.tfvars` and re-apply — no module or
`.tf` edits needed:

```hcl
applications = {
  app1 = { name = "nginx-app1" }
  app2 = { name = "nginx-app2" }
  app3 = { name = "nginx-app3" }   # <-- new app
}
```

Only `name` is required. Each app may optionally override its image, port and sizing:

```hcl
app4 = {
  name           = "custom-app"
  image          = "httpd:latest"
  container_port = 80
  cpu            = 512
  memory         = 1024
  desired_count  = 2
}
```

Then `terraform apply` (or run the GitHub Actions workflow). The new app gets its own
ALB, target group, security groups, task definition and service, and shows up under
`terraform output application_urls`.

Other outputs:

- `cluster_name` — name of the shared ECS cluster
- `vpc_id` — ID of the VPC

## Deploying to both regions

Repeat the deploy steps in the second environment directory. Each environment has its
own independent Terraform state:

```bash
cd environments/us-west-2
terraform init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="key=ecs-nginx/us-west-2/terraform.tfstate" \
  -backend-config="region=<state-bucket-region>" \
  -backend-config="dynamodb_table=<your-lock-table>" \
  -backend-config="encrypt=true"
terraform apply
```

## Destroy

From the same environment directory you applied in:

```bash
cd environments/us-east-1   # or environments/us-west-2
terraform destroy
```

Destroy each environment you deployed. This tears down all resources (ECS services,
ALBs, NAT Gateway, EIP, VPC, etc.) and stops further AWS charges.

## Deploy with GitHub Actions (OIDC + remote state)

The repo includes a workflow at `.github/workflows/terraform.yml` that runs
`init`/`plan`/`apply`/`destroy` for a chosen region. It authenticates to AWS with
**GitHub OIDC** (no stored access keys) and stores Terraform state in **S3 with a
DynamoDB lock** (`environments/*/backend.tf`). The following one-time setup is
required before the first run.

### 1. Create the remote state backend (one-time, per AWS account)

Pick a region to hold state (e.g. `us-east-1`) and a globally-unique bucket name:

```bash
STATE_REGION=us-east-1
STATE_BUCKET=ecs-nginx-tfstate-<your-unique-suffix>
LOCK_TABLE=ecs-nginx-tf-locks

# S3 bucket for state (versioned + encrypted)
aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$STATE_REGION" \
  $( [ "$STATE_REGION" = "us-east-1" ] || echo --create-bucket-configuration LocationConstraint="$STATE_REGION" )
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# DynamoDB table for state locking
aws dynamodb create-table --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region "$STATE_REGION"
```

### 2. Create the GitHub OIDC provider + IAM role (one-time, per AWS account)

Create the OIDC identity provider (skip if it already exists in the account):

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
```

Create an IAM role the workflow can assume. Trust policy (replace `<ACCOUNT_ID>` and
`<OWNER>/<REPO>`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPO>:*"
        }
      }
    }
  ]
}
```

```bash
aws iam create-role --role-name ecs-nginx-gha-terraform \
  --assume-role-policy-document file://trust-policy.json
```

Attach permissions to the role. For a demo you can attach `PowerUserAccess` plus
`IAMFullAccess` (the project creates IAM roles), or scope a custom policy to the
services listed under [Prerequisites](#prerequisites) **plus** access to the state
bucket and lock table:

```bash
aws iam attach-role-policy --role-name ecs-nginx-gha-terraform \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
aws iam attach-role-policy --role-name ecs-nginx-gha-terraform \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

### 3. Set GitHub Actions repository variables

In **Settings → Secrets and variables → Actions → Variables**, add these
(non-secret) repository variables — the workflow reads them as `vars.*`:

| Variable | Example value |
| --- | --- |
| `AWS_ROLE_ARN` | `arn:aws:iam::<ACCOUNT_ID>:role/ecs-nginx-gha-terraform` |
| `TF_STATE_BUCKET` | `ecs-nginx-tfstate-<your-unique-suffix>` |
| `TF_STATE_LOCK_TABLE` | `ecs-nginx-tf-locks` |
| `TF_STATE_REGION` | `us-east-1` |

No secrets are needed — OIDC handles auth. (Optionally create GitHub **Environments**
named `us-east-1` and `us-west-2` to add manual approval gates; the workflow already
references them.)

### 4. Run the workflow

Push this repo to GitHub, then go to **Actions → Terraform → Run workflow** and choose:

- **region** — `us-east-1` or `us-west-2`
- **action** — `plan` (preview), `apply` (deploy), or `destroy` (tear down)

`init` runs automatically with the S3 backend wired to a per-region state key
(`ecs-nginx/<region>/terraform.tfstate`). On `apply`, the app URLs are printed in the
**Show outputs** step.

## Cost note

This stack provisions billable resources, primarily: **2 Application Load Balancers**
and **1 NAT Gateway** per region (plus their data processing), and the running Fargate
tasks. Remember to `terraform destroy` when you are done to avoid ongoing charges.
