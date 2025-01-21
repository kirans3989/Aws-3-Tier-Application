# AWS Three-Tier Architecture Implementation Guide (Terraform)

This guide provides instructions for implementing a three-tier architecture using Terraform with workspaces and modules.

## Project Structure

```
terraform/
├── main.tf                 # Main configuration file
├── variables.tf            # Root variables
├── outputs.tf             # Root outputs
├── providers.tf           # Provider configuration
├── modules/              # Modular components
│   ├── vpc/             # VPC module
│   ├── security/        # Security groups module
│   ├── database/        # RDS module
│   ├── application/     # App tier module
│   └── frontend/        # Frontend module
└── environments/        # Environment-specific configurations
    ├── dev/            # Development environment
    └── prod/           # Production environment
```

## Prerequisites

1. **Required Tools**
   - Terraform (v1.0.0+)
   - AWS CLI configured with appropriate credentials
   - Git

2. **AWS Account Setup**
   - IAM user with appropriate permissions
   - Access key and secret key configured

## Module Structure

Each module follows a standard structure:
```
module/
├── main.tf          # Main module configuration
├── variables.tf     # Input variables
└── outputs.tf       # Output values
```

## Environment Management

### Using Terraform Workspaces

1. **Initialize Terraform Backend**
```bash
# Create S3 bucket for state storage
aws s3 mb s3://your-terraform-state-bucket

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket your-terraform-state-bucket \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

2. **Configure Backend (providers.tf)**
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "three-tier/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

3. **Create Workspaces**
```bash
# List existing workspaces
terraform workspace list

# Create development workspace
terraform workspace new dev

# Create production workspace
terraform workspace new prod

# Switch between workspaces
terraform workspace select dev
```

### Environment-Specific Variables

1. **Create Variable Files**

For development (terraform.tfvars.dev):
```hcl
environment = "dev"
vpc_cidr    = "10.0.0.0/16"
db_name     = "appdb"
db_username = "admin"
```

For production (terraform.tfvars.prod):
```hcl
environment = "prod"
vpc_cidr    = "10.0.0.0/16"
db_name     = "appdb"
db_username = "admin"
```

2. **Sensitive Variables**
Create a separate file for sensitive data (secrets.tfvars):
```hcl
db_password = "your-secure-password"
```

## Deployment Steps

1. **Initialize Project**
```bash
# Initialize Terraform
terraform init

# Select workspace
terraform workspace select dev  # or prod
```

2. **Plan Deployment**
```bash
# For development
terraform plan \
  -var-file="terraform.tfvars.dev" \
  -var-file="secrets.tfvars"

# For production
terraform plan \
  -var-file="terraform.tfvars.prod" \
  -var-file="secrets.tfvars"
```

3. **Apply Configuration**
```bash
# For development
terraform apply \
  -var-file="terraform.tfvars.dev" \
  -var-file="secrets.tfvars"

# For production
terraform apply \
  -var-file="terraform.tfvars.prod" \
  -var-file="secrets.tfvars"
```

4. **Verify Deployment**
```bash
# Show outputs
terraform output

# List resources
terraform state list
```

## Module Usage

### VPC Module
```hcl
module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}
```

### Security Module
```hcl
module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}
```

### Database Module
```hcl
module "database" {
  source = "./modules/database"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.database_subnet_ids
  security_group_id = module.security.db_security_group_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}
```

## Best Practices

1. **State Management**
   - Use remote state storage (S3)
   - Enable state locking (DynamoDB)
   - Use workspaces for environment isolation

2. **Security**
   - Store sensitive variables separately
   - Use KMS encryption for sensitive data
   - Follow least privilege principle
   - Enable versioning for state bucket

3. **Module Design**
   - Keep modules focused and single-purpose
   - Use consistent variable naming
   - Document all variables and outputs
   - Include README for each module

4. **Tagging Strategy**
```hcl
tags = {
  Environment = var.environment
  Project     = "three-tier-app"
  ManagedBy   = "terraform"
}
```

## Maintenance

1. **Regular Updates**
```bash
# Update providers
terraform init -upgrade

# Check for drift
terraform plan
```

2. **State Management**
```bash
# List resources
terraform state list

# Show specific resource
terraform state show aws_vpc.main
```

3. **Cleanup**
```bash
# Destroy resources
terraform destroy \
  -var-file="terraform.tfvars.${workspace}" \
  -var-file="secrets.tfvars"

# Delete workspace (if needed)
terraform workspace select default
terraform workspace delete dev
```

## Troubleshooting

1. **State Lock Issues**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

2. **Plan/Apply Failures**
- Check AWS credentials
- Verify variable values
- Check resource dependencies
- Review error messages in detail

3. **Module Issues**
- Verify module source paths
- Check variable declarations
- Validate outputs usage

## Security Considerations

1. **State File Security**
   - Enable encryption at rest
   - Use HTTPS for state access
   - Restrict bucket access
   - Enable bucket versioning

2. **Access Control**
   - Use IAM roles
   - Implement least privilege
   - Regular credential rotation
   - Enable AWS CloudTrail

3. **Network Security**
   - Use private subnets
   - Implement NACLs
   - Configure security groups
   - Enable VPC Flow Logs

## Monitoring and Logging

1. **CloudWatch Integration**
   - Enable detailed monitoring
   - Set up log groups
   - Configure metrics
   - Create alarms

2. **AWS Config**
   - Enable configuration recording
   - Set up rules
   - Monitor compliance

Remember to always review changes before applying them to production and maintain proper documentation for all modifications.