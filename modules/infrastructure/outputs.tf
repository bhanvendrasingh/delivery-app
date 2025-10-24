# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

# Database Outputs
output "mongodb_endpoint" {
  description = "MongoDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
}

output "mongodb_port" {
  description = "MongoDB cluster port"
  value       = aws_docdb_cluster.main.port
}


# Elasticsearch Outputs
output "elasticsearch_endpoint" {
  description = "Elasticsearch domain endpoint"
  value       = var.enable_elasticsearch ? aws_elasticsearch_domain.main[0].endpoint : null
}

# Website Outputs
output "website_bucket_name" {
  description = "Name of the S3 bucket for website hosting"
  value       = var.enable_website ? aws_s3_bucket.website[0].bucket : null
}

output "website_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = var.enable_website ? aws_s3_bucket.website[0].bucket_domain_name : null
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_website ? aws_cloudfront_distribution.website[0].id : null
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.enable_website ? aws_cloudfront_distribution.website[0].domain_name : null
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = var.enable_website ? aws_cloudfront_distribution.website[0].arn : null
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}
# WAF Output
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.environment == "prod" ? aws_wafv2_web_acl.main[0].arn : null
}

# Data Bucket Outputs
output "data_bucket_name" {
  description = "Name of the S3 data bucket"
  value       = var.enable_data_bucket ? aws_s3_bucket.data[0].bucket : null
}

output "data_bucket_arn" {
  description = "ARN of the S3 data bucket"
  value       = var.enable_data_bucket ? aws_s3_bucket.data[0].arn : null
}

output "data_bucket_domain_name" {
  description = "Domain name of the S3 data bucket"
  value       = var.enable_data_bucket ? aws_s3_bucket.data[0].bucket_domain_name : null
}

output "data_bucket_region" {
  description = "Region of the S3 data bucket"
  value       = var.enable_data_bucket ? aws_s3_bucket.data[0].region : null
}