############################################
# Remote backend: S3 (state) + DynamoDB (lock)
# NOTE: backend blocks cannot use variables.
# Replace the placeholder values below, or pass
# them via `terraform init -backend-config=...`
############################################
terraform {
  backend "s3" {
    bucket         = "REPLACE-WITH-YOUR-STATE-BUCKET"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
