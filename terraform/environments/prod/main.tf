terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "three-tier/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

module "three_tier_app" {
  source = "../../"

  environment = "prod"
  vpc_cidr    = "10.30.0.0/16"
  db_name     = "appdb"
  db_username = "admin"
  db_password = var.db_password
}