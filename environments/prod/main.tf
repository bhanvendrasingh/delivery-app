terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "go-bharat-tf-state-production"
    dynamodb_table = "go-bharat-terraform-lock-production"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-2"
  }
}

# Backend state management
module "backend" {
  source      = "../../modules/backend"
  bucket_name = "go-bharat-tf-state-production"
  table_name  = "go-bharat-terraform-lock-production"
}

module "go_bharat_infrastructure" {
  source = "../../modules/infrastructure"

  # Environment Configuration
  environment = "prod"
  project     = "go-bharat"
  
  # Network Configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-south-2a", "ap-south-2b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  # Compute Configuration
  instance_types = ["t3.medium", "t3a.medium", "t2.medium"]
  spot_instances = {
    min = 2
    max = 6
  }
  
  # MongoDB Configuration
  mongodb_cluster = {
    engine_version   = "5.0.0"
    instance_class   = "db.r6g.large"
    instance_count   = 3
    backup_retention = 30
    tls_enabled      = true
    kms_key_id       = null # Set to specific KMS key ARN for production encryption
  }
  
  # Microservices Configuration
  applications = {
    communication-service = {
      image_tag = "communication-service"
      cpu       = 512
      memory    = 1024
      port      = 8787
      replicas  = 2
      health_check_path = "/api/communication/health"
    }
    delivery-partner-service = {
      image_tag = "delivery-partner-service"
      cpu       = 512
      memory    = 1024
      port      = 8686
      replicas  = 2
      health_check_path = "/api/partner/health"
    }
    payment-service = {
      image_tag = "payment-service"
      cpu       = 1024
      memory    = 2048
      port      = 8085
      replicas  = 3
      health_check_path = "/api/payment/health"
    }
    support-agent-service = {
      image_tag = "support-agent-service"
      cpu       = 512
      memory    = 1024
      port      = 9191
      replicas  = 2
      health_check_path = "/api/support/orders/count"
    }
    data-sync-service = {
      image_tag = "data-sync-service"
      cpu       = 512
      memory    = 1024
      port      = 9797
      replicas  = 2
      health_check_path = "/api/data-sync/health"
    }
    order-service = {
      image_tag = "order-service"
      cpu       = 1024
      memory    = 2048
      port      = 8383
      replicas  = 3
      health_check_path = "/api/order/health"
    }
    restaurant-service = {
      image_tag = "restaurant-service"
      cpu       = 1024
      memory    = 2048
      port      = 80
      replicas  = 3
      health_check_path = "/api/restaurant/health"
    }
    customer-service = {
      image_tag = "customer-service"
      cpu       = 1024
      memory    = 2048
      port      = 8585
      replicas  = 3
      health_check_path = "/api/customer/health"
    }
  }
  
  # Load Balancer Configuration
  enable_https = true
  
  # Monitoring Configuration
  enable_container_insights = true
  log_retention_days       = 30
  
  # MongoDB credentials (should be managed via AWS Secrets Manager)
  mongodb_username = "go_bharat_prod"
  # mongodb_password should be retrieved from AWS Secrets Manager
  
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
    Owner       = "Platform Team"
    CostCenter  = "Production"
    Backup      = "Critical"
    Compliance  = "Required"
  }
}