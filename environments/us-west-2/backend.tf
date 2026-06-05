# Remote state backend (S3 + DynamoDB lock).
#
# This is a PARTIAL configuration on purpose: the bucket, key, region and lock
# table are supplied at `terraform init` time via `-backend-config` flags (see
# the GitHub Actions workflow) so no account-specific values are committed.
#
# Local init example:
#   terraform init \
#     -backend-config="bucket=<your-state-bucket>" \
#     -backend-config="key=ecs-nginx/us-west-2/terraform.tfstate" \
#     -backend-config="region=<state-bucket-region>" \
#     -backend-config="dynamodb_table=<your-lock-table>" \
#     -backend-config="encrypt=true"
terraform {
  backend "s3" {}
}
