# QA Environment Configuration
environment = "qa"
project     = "go-bharat"

# MongoDB credentials (use AWS Secrets Manager in production)
mongodb_username = "go_bharat_qa"
mongodb_password = "ChangeMe123!" # This should be managed via AWS Secrets Manager

# ECR Repository URLs
ecr_repositories = {
  webapp = "067010549378.dkr.ecr.ap-south-2.amazonaws.com/go-bharat-webapp-qa"
  tenant = "067010549378.dkr.ecr.ap-south-2.amazonaws.com/go-bharat-tenant-qa"
}

# Resource Tags
additional_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Backup      = "Required"
}