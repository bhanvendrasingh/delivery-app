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
    min = 2
    max = 5
    desired = 3
  }

  ## key for autoscalling
  ecs-ec2-key = "go-bharat"
  
  # MongoDB Configuration
  mongodb_cluster = {
    engine_version   = "5.0.0"
    instance_class   = "db.t3.medium"
    instance_count   = 1
    backup_retention = 7
    tls_enabled      = true
    kms_key_id       = null
  }

    # MongoDB credentials
  mongodb_username = "go_bharat_qa"
  mongodb_password = null # Should be managed via AWS Secrets Manager
  mongodb_uri = "mongodb://go_bharat_qa:uPm7j8E05h2L0wci@go-bharat-qa-mongodb-cluster.cluster-cheo4so26vyv.ap-south-2.docdb.amazonaws.com:27017/go_bharat_qa?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  
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
      memory    = 512
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
      memory    = 512
      port      = 8383
      replicas  = 1
    }
    restaurant-service = {
      image_tag = "restaurant-service"
      cpu       = 512
      memory    = 512
      port      = 8282
      replicas  = 1
    }
    customer-service = {
      image_tag = "customer-service"
      cpu       = 512
      memory    = 512
      port      = 8585
      replicas  = 1
    }
    api-gateway-service = {
      image_tag = "api-gateway-service"
      cpu       = 512
      memory    = 512
      port      = 8081
      replicas  = 1
    }
  }
  
  # Load Balancer Configuration
  enable_https = true
  ssl_certificate_arn = "arn:aws:acm:ap-south-2:692859922629:certificate/cbe34c17-b40e-486b-a2b0-72d27610dcc0"  # Replace with your actual certificate ARN
  
  # Monitoring Configuration
  enable_container_insights = true
  log_retention_days       = 7
  
  #ECR Repository URLs (using existing repository)
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

  # elasticsearch configration
  enable_elasticsearch = true
  elasticsearch = {
    version = "7.10"
    instance_type = "t3.small.elasticsearch"
    instance_count = "1"
    volume_size = "10"
    dedicated_master_enabled = false
    dedicated_master_type = "t3.small.elasticsearch"
    dedicated_master_count = "0"
    tls_enabled = true
  }
  
  # Redis Configuratio
  redis = {
    engine_version = "7.2"
    engine = "valkey"
    node_type = "cache.t3.micro"  
    num_cache_clusters = 1
    parameter_group_name = "default.valkey7"
    port = 6379
  }
  
  # Kafka Configuration
  # kafka_public_key = file("~/.ssh/id_rsa.pub")
  kafka = {
    instance_count = "1"
    instance_type  = "t3.small"  # Free tier eligible
    volume_size    = "20"
    tls_enabled    = "true"
    key_name       = "go-bharat-kafka-ec2"
    }
  
  # Website Configuration
  enable_website = true
  website_config = {
    default_root_object  = "index.html"
    custom_domain       = null  # Set to your QA domain (e.g., "qa.gobharatfresh.com")
    ssl_certificate_arn = null  # Add your SSL certificate ARN if you have a custom domain
    price_class        = "PriceClass_100"
    alb_domain_name    = null  # Will use the ALB created by this module
  }
  
  # Data Bucket Configuration
  enable_data_bucket = true
  
  # Additional tags
  additional_tags = {
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Backup      = "Required"
  }
}

