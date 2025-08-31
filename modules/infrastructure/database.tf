# # Random password for MongoDB cluster
# resource "random_password" "mongodb_password" {
#   count   = var.mongodb_password == null ? 1 : 0
#   length  = 16
#   special = false # DocumentDB doesn't support special characters in passwords
# }

# # DocumentDB Subnet Group
# resource "aws_docdb_subnet_group" "main" {
#   name       = "${local.name_prefix}-docdb-subnet-group"
#   subnet_ids = module.vpc.private_subnets

#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-docdb-subnet-group"
#   })
# }

# # DocumentDB Cluster Parameter Group
# resource "aws_docdb_cluster_parameter_group" "main" {
#   family = "docdb5.0"
#   name   = "${local.name_prefix}-docdb-params"

#   parameter {
#     name  = "tls"
#     value = var.mongodb_cluster.tls_enabled ? "enabled" : "disabled"
#   }

#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-docdb-params"
#   })
# }

# # DocumentDB Cluster
# resource "aws_docdb_cluster" "main" {
#   cluster_identifier      = "${local.name_prefix}-mongodb-cluster"
#   engine                  = "docdb"
#   engine_version          = var.mongodb_cluster.engine_version
#   master_username         = var.mongodb_username
#   master_password         = var.mongodb_password != null ? var.mongodb_password : random_password.mongodb_password[0].result
  
#   # Network Configuration
#   db_subnet_group_name   = aws_docdb_subnet_group.main.name
#   vpc_security_group_ids = [aws_security_group.mongodb.id]
  
#   # Backup Configuration
#   backup_retention_period = var.mongodb_cluster.backup_retention
#   preferred_backup_window = "03:00-04:00"
#   preferred_maintenance_window = "sun:04:00-sun:05:00"
  
#   # Security Configuration
#   storage_encrypted = true
#   kms_key_id       = var.mongodb_cluster.kms_key_id
  
#   # Cluster Configuration
#   db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  
#   # Deletion Protection
#   deletion_protection = var.enable_deletion_protection && var.environment == "prod"
#   skip_final_snapshot = var.environment != "prod"
#   final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-mongodb-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
#   # Enable CloudWatch logs
#   enabled_cloudwatch_logs_exports = ["audit", "profiler"]

#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-mongodb-cluster"
#   })

#   lifecycle {
#     ignore_changes = [master_password]
#   }
# }

# # DocumentDB Cluster Instances
# resource "aws_docdb_cluster_instance" "cluster_instances" {
#   count              = var.mongodb_cluster.instance_count
#   identifier         = "${local.name_prefix}-mongodb-${count.index}"
#   cluster_identifier = aws_docdb_cluster.main.id
#   instance_class     = var.mongodb_cluster.instance_class

#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-mongodb-${count.index}"
#   })
# }



# # SSM Parameters for MongoDB connection
# resource "aws_ssm_parameter" "mongodb_username" {
#   name  = "/${var.project}/${var.environment}/mongodb/username"
#   type  = "String"
#   value = var.mongodb_username

#   tags = local.common_tags
# }

# resource "aws_ssm_parameter" "mongodb_password" {
#   name  = "/${var.project}/${var.environment}/mongodb/password"
#   type  = "SecureString"
#   value = var.mongodb_password != null ? var.mongodb_password : random_password.mongodb_password[0].result

#   tags = local.common_tags

#   lifecycle {
#     ignore_changes = [value]
#   }
# }

# resource "aws_ssm_parameter" "mongodb_connection_string" {
#   name  = "/${var.project}/${var.environment}/mongodb/connection_string"
#   type  = "SecureString"
#   value = "mongodb://${var.mongodb_username}:${var.mongodb_password != null ? var.mongodb_password : random_password.mongodb_password[0].result}@${aws_docdb_cluster.main.endpoint}:27017/${local.mongodb_database}?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"

#   tags = local.common_tags

#   lifecycle {
#     ignore_changes = [value]
#   }
# }

# resource "aws_ssm_parameter" "mongodb_endpoint" {
#   name  = "/${var.project}/${var.environment}/mongodb/endpoint"
#   type  = "String"
#   value = aws_docdb_cluster.main.endpoint

#   tags = local.common_tags
# }

# resource "aws_ssm_parameter" "mongodb_port" {
#   name  = "/${var.project}/${var.environment}/mongodb/port"
#   type  = "String"
#   value = "27017"

#   tags = local.common_tags
# }