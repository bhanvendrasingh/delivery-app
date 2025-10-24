terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "go-bharat-tf-state-production"
    dynamodb_table = "go-bharat-terraform-lock-production"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-2"
  }
}

module "go_bharat_infrastructure" {
  source = "../../modules/infrastructure"

  # Environment Configuration
  environment = "prod"
  project     = "go-bharat"
  
  # Network Configuration - Production uses different CIDR to avoid conflicts
  vpc_cidr             = "10.2.0.0/16"
  availability_zones   = ["ap-south-2a", "ap-south-2b", "ap-south-2c"]  # Use all 3 AZs for HA
  private_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
  
  # Compute Configuration - NO SPOT INSTANCES in Production
  instance_types = ["m5.large", "m5.xlarge", "c5.large"]  # Production-grade instances
  spot_instances = {
    min = 0  # No spot instances in production
    max = 0
  }

  ## key for autoscaling - Production key
  ecs-ec2-key = "go-bharat-prod"
  
  # MongoDB Configuration - Production-grade with Multi-AZ
  mongodb_cluster = {
    engine_version   = "5.0.0"
    instance_class   = "db.r6g.large"  # Production instance class
    instance_count   = 3               # Multi-AZ cluster
    backup_retention = 30              # 30 days backup retention
    tls_enabled      = true
    kms_key_id       = null            # Add KMS key ARN for encryption
  }

  # MongoDB credentials - Production
  mongodb_username = "go_bharat_prod"
  mongodb_password = null # MUST be managed via AWS Secrets Manager in production
  mongodb_uri = null      # Will be constructed from cluster endpoint
  
  # Microservices Configuration - Production-grade with HA
  applications = {
    communication-service = {
      image_tag = "communication-service"
      cpu       = 512   # Doubled for production
      memory    = 1024  # Doubled for production
      port      = 8787
      replicas  = 3     # High availability
    }
    delivery-partner-service = {
      image_tag = "delivery-partner-service"
      cpu       = 512
      memory    = 1024
      port      = 8686
      replicas  = 3
    }
    payment-service = {
      image_tag = "payment-service"
      cpu       = 1024  # Critical service - more resources
      memory    = 2048
      port      = 8085
      replicas  = 5     # Critical service - more replicas
    }
    support-agent-service = {
      image_tag = "support-agent-service"
      cpu       = 512
      memory    = 1024
      port      = 9191
      replicas  = 2
    }
    data-sync-service = {
      image_tag = "data-sync-service"
      cpu       = 512
      memory    = 1024
      port      = 9797
      replicas  = 3
    }
    order-service = {
      image_tag = "order-service"
      cpu       = 1024  # Critical service - more resources
      memory    = 2048
      port      = 8383
      replicas  = 5     # Critical service - more replicas
    }
    restaurant-service = {
      image_tag = "restaurant-service"
      cpu       = 1024
      memory    = 2048
      port      = 8282
      replicas  = 4
    }
    customer-service = {
      image_tag = "customer-service"
      cpu       = 1024
      memory    = 2048
      port      = 8585
      replicas  = 4
    }
    api-gateway-service = {
      image_tag = "api-gateway-service"
      cpu       = 1024  # Gateway - more resources
      memory    = 2048
      port      = 8081
      replicas  = 5     # Gateway - more replicas
    }
  }
  
  # Load Balancer Configuration
  enable_https = true
  
  
  # WAF Configuration (Production Only)
  waf_config = {
    rate_limit        = 2000  # Requests per 5-minute window per IP
    blocked_countries = []    # Add country codes to block (e.g., ["CN", "RU"])
    allowed_ips       = []    # Add specific IPs to always allow (e.g., ["1.2.3.4/32"])
  }
  
  # Monitoring Configuration - Production-grade
  enable_container_insights = true
  log_retention_days       = 30  # 30 days for production compliance
  
  # ECR Repository URLs - Production repositories
  ecr_repositories = {
    communication-service     = "" 
    delivery-partner-service  = ""
    payment-service           = ""
    support-agent-service     = ""
    data-sync-service         = ""
    order-service             = ""
    restaurant-service        = ""  ## Dependency on elastic search, redish, mongo
    customer-service          = ""
    api-gateway-service       = ""  ## working
  }

  # Elasticsearch Configuration - Production-grade
  enable_elasticsearch = true
  elasticsearch = {
    version = "7.10"
    instance_type = "r6g.large.elasticsearch"  # Production instance type
    instance_count = "3"                       # Multi-AZ cluster
    volume_size = "100"                        # 100GB for production
    dedicated_master_enabled = true            # Dedicated master nodes
    dedicated_master_type = "r6g.medium.elasticsearch"
    dedicated_master_count = "3"               # 3 master nodes for HA
    tls_enabled = true
  }
  
  # Redis Configuration - Production-grade
  redis = {
    engine_version = "7.2"
    engine = "valkey"
    node_type = "cache.r6g.large"              # Production instance type
    num_cache_clusters = 3                     # Multi-AZ cluster
    parameter_group_name = "default.valkey7"
    port = 6379
  }
  
  # Kafka Configuration - Production-grade
  kafka = {
    instance_count = "3"                       # Multi-AZ cluster
    instance_type  = "m5.large"                # Production instance type
    volume_size    = "100"                     # 100GB for production
    tls_enabled    = "true"
    key_name       = "go-bharat-kafka-prod"    # Production key
  }
  
  # Website Configuration - Production
  enable_website = true
  website_config = {
    default_root_object  = "index.html"
    custom_domain       = "gobharatfresh.com"  # Production domain
    ssl_certificate_arn = null                 # Will use the certificate created by ssl_config
    price_class        = "PriceClass_All"      # Global distribution for production
    alb_domain_name    = null                  # Will use the ALB created by this module
  }
  
  # Data Bucket Configuration - Production
  enable_data_bucket = true
  
  # Security Configuration - Production
  enable_deletion_protection = true  # Prevent accidental deletion
  
  # Additional tags - Production
  additional_tags = {
    Owner       = "Platform Team"
    CostCenter  = "Production"
    Backup      = "Critical"
    Compliance  = "Required"
    Environment = "Production"
    Monitoring  = "24x7"
  }
}

