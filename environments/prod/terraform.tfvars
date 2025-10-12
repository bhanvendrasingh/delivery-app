# Production Environment Configuration
environment = "prod"
project     = "go-bharat"

# MongoDB credentials (managed via AWS Secrets Manager)
mongodb_username = "go_bharat_prod"
# mongodb_password should be retrieved from AWS Secrets Manager

# ECR Repository URLs
ecr_repositories = {
  webapp = "067010549378.dkr.ecr.ap-south-2.amazonaws.com/go-bharat-webapp"
  tenant = "067010549378.dkr.ecr.ap-south-2.amazonaws.com/go-bharat-tenant"
}

# Resource Tags
additional_tags = {
  Owner       = "Platform Team"
  CostCenter  = "Production"
  Backup      = "Critical"
  Compliance  = "Required"
}