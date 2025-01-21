module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "database" {
  source = "./modules/database"

  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.database_subnet_ids
  security_group_id  = module.security.db_security_group_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}

module "application" {
  source = "./modules/application"

  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_id  = module.security.app_security_group_id
  instance_type      = var.instance_type
  db_endpoint        = module.database.rds_endpoint
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

module "frontend" {
  source = "./modules/frontend"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.web_security_group_id
  app_target_group  = module.application.target_group_arn
}