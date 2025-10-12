# # VPC Outputs
# output "vpc_id" {
#   description = "ID of the VPC"
#   value       = module.vpc.vpc_id
# }

# output "vpc_cidr_block" {
#   description = "CIDR block of the VPC"
#   value       = module.vpc.vpc_cidr_block
# }

# output "private_subnet_ids" {
#   description = "IDs of the private subnets"
#   value       = module.vpc.private_subnets
# }

# output "public_subnet_ids" {
#   description = "IDs of the public subnets"
#   value       = module.vpc.public_subnets
# }

# # ECS Outputs
# output "ecs_cluster_id" {
#   description = "ID of the ECS cluster"
#   value       = aws_ecs_cluster.main.id
# }

# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = aws_ecs_cluster.main.name
# }

# # Load Balancer Outputs
# output "alb_dns_name" {
#   description = "DNS name of the load balancer"
#   value       = aws_lb.main.dns_name
# }

# output "alb_zone_id" {
#   description = "Zone ID of the load balancer"
#   value       = aws_lb.main.zone_id
# }

# output "alb_arn" {
#   description = "ARN of the load balancer"
#   value       = aws_lb.main.arn
# }

# # MongoDB Database Outputs
# output "mongodb_cluster_endpoint" {
#   description = "MongoDB DocumentDB cluster endpoint"
#   value       = aws_docdb_cluster.main.endpoint
#   sensitive   = true
# }

# output "mongodb_cluster_reader_endpoint" {
#   description = "MongoDB DocumentDB cluster reader endpoint"
#   value       = aws_docdb_cluster.main.reader_endpoint
#   sensitive   = true
# }

# output "mongodb_port" {
#   description = "MongoDB port"
#   value       = aws_docdb_cluster.main.port
# }

# output "mongodb_cluster_id" {
#   description = "MongoDB DocumentDB cluster identifier"
#   value       = aws_docdb_cluster.main.cluster_identifier
# }

# # Microservices Outputs
# output "microservices_info" {
#   description = "Microservices deployment information"
#   value = {
#     ecr_base_uri = local.ecr_base_uri
#     services     = local.microservices
#   }
# }

# # Security Group Outputs
# output "security_group_ids" {
#   description = "Security group IDs"
#   value = {
#     alb     = aws_security_group.alb.id
#     ecs     = aws_security_group.ecs.id
#     mongodb = aws_security_group.mongodb.id
#   }
# }

# # Application URLs
# output "application_urls" {
#   description = "Application access URLs"
#   value = {
#     webapp = var.enable_https ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
#   }
# }