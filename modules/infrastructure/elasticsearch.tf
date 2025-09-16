# Elasticsearch Domain
resource "aws_elasticsearch_domain" "main" {
  count                 = var.enable_elasticsearch ? 1 : 0
  domain_name           = "${local.name_prefix}-elasticsearch"
  elasticsearch_version = var.elasticsearch.version

  cluster_config {
    instance_type             = var.elasticsearch.instance_type
    instance_count            = var.environment == "prod" ? 2 : 1
    dedicated_master_enabled  = var.dedicated_master_enabled
    dedicated_master_type     = var.elasticsearch.dedicated_master_type
    dedicated_master_count    = var.elasticsearch.dedicated_master_count
    zone_awareness_enabled    = var.environment == "prod"

    dynamic "zone_awareness_config" {
      for_each = var.environment == "prod" ? [1] : []
      content {
        availability_zone_count = 2
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.elasticsearch.volume_size
    iops        = 3000
    throughput  = 125
  }

  vpc_options {
    subnet_ids = var.environment == "prod" ? module.vpc.private_subnets : [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.elasticsearch.id]
  }

  encrypt_at_rest {
    enabled = var.environment == "prod"
  }

  node_to_node_encryption {
    enabled = var.environment == "prod"
  }

  domain_endpoint_options {
    enforce_https       = var.environment == "prod"
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = var.environment == "prod"
    internal_user_database_enabled = var.environment == "prod"

    dynamic "master_user_options" {
      for_each = var.environment == "prod" ? [1] : []
      content {
        master_user_name     = var.elasticsearch_master_username
        master_user_password = var.elasticsearch_master_password
      }
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.elasticsearch[0].arn
    log_type                 = "INDEX_SLOW_LOGS"
    enabled                  = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.elasticsearch[0].arn
    log_type                 = "SEARCH_SLOW_LOGS"
    enabled                  = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.elasticsearch[0].arn
    log_type                 = "ES_APPLICATION_LOGS"
    enabled                  = true
  }

  tags = local.common_tags

  depends_on = [aws_iam_service_linked_role.elasticsearch]
}


# CloudWatch Log Group for Elasticsearch
resource "aws_cloudwatch_log_group" "elasticsearch" {
  count             = var.enable_elasticsearch ? 1 : 0
  name              = "/aws/elasticsearch/domains/${local.name_prefix}-elasticsearch"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = local.common_tags
}


resource "aws_cloudwatch_log_resource_policy" "es_logs" {
  policy_name = "${local.name_prefix}-es-logs-policy"

  policy_document = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elasticsearch/domains/${local.name_prefix}-elasticsearch*"
    }
  ]
}
POLICY
}



# IAM Service Linked Role for Elasticsearch
resource "aws_iam_service_linked_role" "elasticsearch" {
  count            = var.enable_elasticsearch ? 1 : 0
  aws_service_name = "es.amazonaws.com"
  description      = "Service linked role for Elasticsearch domain"
}

# Elasticsearch Domain Policy
resource "aws_elasticsearch_domain_policy" "main" {
  count       = var.enable_elasticsearch ? 1 : 0
  domain_name = aws_elasticsearch_domain.main[0].domain_name

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "es:*"
        Resource = "${aws_elasticsearch_domain.main[0].arn}/*"
      }
    ]
  })
}

# SSM Parameters for Elasticsearch
resource "aws_ssm_parameter" "elasticsearch_endpoint" {
  count = var.enable_elasticsearch ? 1 : 0
  name  = "/${var.project}/${var.environment}/elasticsearch/endpoint"
  type  = "String"
  value = aws_elasticsearch_domain.main[0].endpoint

  tags = local.common_tags
}

resource "aws_ssm_parameter" "elasticsearch_kibana_endpoint" {
  count = var.enable_elasticsearch ? 1 : 0
  name  = "/${var.project}/${var.environment}/elasticsearch/kibana_endpoint"
  type  = "String"
  value = aws_elasticsearch_domain.main[0].kibana_endpoint

  tags = local.common_tags
}

# SSM Parameters for Elasticsearch credentials
resource "aws_ssm_parameter" "elasticsearch_username" {
  name  = "/${var.project}/${var.environment}/elasticsearch/username"
  type  = "String"
  value = var.elasticsearch_master_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "elasticsearch_password" {
  name  = "/${var.project}/${var.environment}/elasticsearch/password"
  type  = "SecureString"
  value = var.elasticsearch_master_password
  tags  = local.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}
