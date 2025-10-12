resource "aws_elasticache_replication_group" "cache" {
  automatic_failover_enabled  = var.environment == "prod" ? true : false
  preferred_cache_cluster_azs = var.environment == "prod" ? ["ap-south-2a", "ap-south-2b"] : ["ap-south-2a"]
  replication_group_id        = "tf-redis-${var.environment}"
  description                 = "Redis cluster for ${var.environment} environment"
  engine                      = var.redis.engine
  engine_version              = var.redis.engine_version
  node_type                   = var.redis.node_type
  num_cache_clusters          = var.redis.num_cache_clusters
  parameter_group_name        = var.redis.parameter_group_name
  port                        = var.redis.port
  security_group_ids          = [aws_security_group.redis.id]
  subnet_group_name           = aws_elasticache_subnet_group.redis.name
}



resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name_prefix}-cache"
  subnet_ids = module.vpc.public_subnets
}

resource "aws_ssm_parameter" "redis_endpoint" {
  name  = "/${local.name_prefix}/redis/endpoint"
  type  = "String"
  value = aws_elasticache_replication_group.cache.primary_endpoint_address
  tags  = local.common_tags
}