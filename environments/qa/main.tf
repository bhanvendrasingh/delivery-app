terraform {
  backend "s3" {
    use_lockfile   = "true"
    bucket         = "go-bharat-tf-state-qa"
    key            = "qa/terraform.tfstate"
    region         = "ap-south-2"
  }
}


module "go_bharat_infrastructure" {
  source = "../../modules/infrastructure"

  # Environment Configuration
  environment = "qa"
  project     = "go-bharat"
  
  # Network Configuration
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["ap-south-2a", "ap-south-2b"]
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24"]
  
  # Compute Configuration
  instance_types = ["t3.medium", "t3.large"]
  spot_instances = {
    min = 1
    max = 2
  }
  
  # MongoDB Configuration
  mongodb_cluster = {
    engine_version   = "5.0.0"
    instance_class   = "db.t4g.medium"
    instance_count   = 1
    backup_retention = 7
    tls_enabled      = true
    kms_key_id       = null
  }
  
  # Microservices Configuration
  applications = {
    communication-service = {
      image_tag = "communication-service"
      cpu       = 256
      memory    = 512
      port      = 8787
      replicas  = 1
    }
    delivery-partner-service = {
      image_tag = "delivery-partner-service"
      cpu       = 256
      memory    = 512
      port      = 8686
      replicas  = 1
    }
    payment-service = {
      image_tag = "payment-service"
      cpu       = 512
      memory    = 1024
      port      = 8085
      replicas  = 1
    }
    support-agent-service = {
      image_tag = "support-agent-service"
      cpu       = 256
      memory    = 512
      port      = 9191
      replicas  = 1
    }
    data-sync-service = {
      image_tag = "data-sync-service"
      cpu       = 256
      memory    = 512
      port      = 9797
      replicas  = 1
    }
    order-service = {
      image_tag = "order-service"
      cpu       = 512
      memory    = 1024
      port      = 8383
      replicas  = 1
    }
    restaurant-service = {
      image_tag = "restaurant-service"
      cpu       = 512
      memory    = 1024
      port      = 80
      replicas  = 1
    }
    customer-service = {
      image_tag = "customer-service"
      cpu       = 512
      memory    = 1024
      port      = 8585
      replicas  = 1
    }
  }
  
  # Load Balancer Configuration
  enable_https = false
  
  # Monitoring Configuration
  enable_container_insights = true
  log_retention_days       = 7
  
  # MongoDB credentials
  mongodb_username = "go_bharat_qa"
  mongodb_password = "ChangeMe123!" # Should be managed via AWS Secrets Manager
  
  # ECR Repository URLs (using existing repository)
  ecr_repositories = {
    communication-service     = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    delivery-partner-service  = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    payment-service          = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    support-agent-service    = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    data-sync-service        = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    order-service            = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    restaurant-service       = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
    customer-service         = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"
  }
  
  # Additional tags
  additional_tags = {
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Backup      = "Required"
  }
}