locals {
  # Common naming convention
  name_prefix = "${var.project}-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )
  
  # MongoDB database configuration
  mongodb_database = replace("${var.project}_${var.environment}", "-", "_")
  
  # ECS cluster name
  cluster_name = "${local.name_prefix}-cluster"
  
  # Load balancer name
  alb_name = "${local.name_prefix}-alb"
  
  # Security group names
  sg_names = {
    alb     = "${local.name_prefix}-alb-sg"
    ecs     = "${local.name_prefix}-ecs-sg"
    mongodb = "${local.name_prefix}-mongodb-sg"
    redis   = "${local.name_prefix}-redis-sg"
    elasticsearch = "${local.name_prefix}-elasticsearch-sg"
  }
  
  # Microservices configuration
  microservices = {
    communication-service    = "communication-service"
    delivery-partner-service = "delivery-partner-service"
    payment-service          = "payment-service"
    support-agent-service    = "support-agent-service"
    data-sync-service        = "data-sync-service"
    order-service            = "order-service"
    restaurant-service       = "restaurant-service"
    customer-service         = "customer-service"
    api-gateway-service      = "api-gateway-service"
  }
  
  # ECR repository base URI (temporary use)
  ecr_base_uri = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat"

  #configration for eleastic search 
  dedicated_master_enabled = false
  elasticsearch_config = {
    cluster_name            = "${local.name_prefix}-elasticsearch"
    node_name               = "${local.name_prefix}-es-node"
    security_enabled        = var.environment == "prod"
    http_ssl_enabled        = var.environment == "prod"
    transport_ssl_enabled   = var.environment == "prod"
    monitoring_enabled      = true
    log_level               = var.environment == "prod" ? "INFO" : "DEBUG"
  }
}