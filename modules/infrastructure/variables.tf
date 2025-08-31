# Core Configuration
variable "environment" {
  description = "Environment name (qa, prod)"
  type        = string
  validation {
    condition     = contains(["qa", "prod"], var.environment)
    error_message = "Environment must be either 'qa' or 'prod'."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "go-bharat"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-2"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

# Compute Configuration
variable "instance_types" {
  description = "List of EC2 instance types for ECS cluster"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "spot_instances" {
  description = "Auto Scaling Group configuration for spot instances"
  type = object({
    min = number
    max = number
  })
}

# MongoDB Configuration
variable "mongodb_cluster" {
  description = "MongoDB DocumentDB cluster configuration"
  type = object({
    engine_version   = string
    instance_class   = string
    instance_count   = number
    backup_retention = number
    tls_enabled      = bool
    kms_key_id       = optional(string)
  })
}

variable "mongodb_username" {
  description = "MongoDB master username"
  type        = string
  default     = "go_bharat_admin"
}

variable "mongodb_password" {
  description = "MongoDB master password"
  type        = string
  sensitive   = true
  default     = null
}

# Application Configuration
variable "applications" {
  description = "Application configuration for ECS services"
  type = map(object({
    image_tag = string
    cpu       = number
    memory    = number
    port      = number
    replicas  = number
    health_check_path = optional(string, "/health")
  }))
}

variable "ecr_repositories" {
  description = "ECR repository URLs for microservices"
  type = map(string)
  default = {
    communication-service     = ""
    delivery-partner-service  = ""
    payment-service          = ""
    support-agent-service    = ""
    data-sync-service        = ""
    order-service            = ""
    restaurant-service       = ""
    customer-service         = ""
  }
}

# Load Balancer Configuration
variable "enable_https" {
  description = "Enable HTTPS on load balancer"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
  default     = null
}

# Monitoring Configuration
variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

# Tagging
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}