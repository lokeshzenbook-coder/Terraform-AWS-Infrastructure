terraform {
  backend "s3" {
    bucket         = "REPLACE-WITH-YOUR-STATE-BUCKET"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
