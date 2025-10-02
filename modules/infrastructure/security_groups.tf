# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${local.sg_names.alb}-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Application Load Balancer"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = merge(local.common_tags, {
    Name = local.sg_names.alb
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name_prefix = "${local.sg_names.ecs}-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for ECS microservices"

  # Allow traffic from ALB to all microservices ports
  dynamic "ingress" {
    for_each = var.applications
    content {
      description     = "HTTP from ALB to ${ingress.key}"
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      protocol        = "tcp"
      security_groups = [aws_security_group.alb.id]
    }
  }

  # Allow inter-service communication within ECS cluster
  ingress {
    description = "Inter-service communication"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = merge(local.common_tags, {
    Name = local.sg_names.ecs
  })

  lifecycle {
    create_before_destroy = true
  }
}

# MongoDB DocumentDB Security Group
resource "aws_security_group" "mongodb" {
  name_prefix = "${local.sg_names.mongodb}-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for MongoDB DocumentDB cluster"

  ingress {
    description     = "MongoDB from ECS"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = merge(local.common_tags, {
    Name = local.sg_names.mongodb
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Opensearch(eleastic-search) Security Group
resource "aws_security_group" "elasticsearch" {
  name_prefix = "${local.sg_names.elasticsearch}"
  description = "Security Group for Elasticsearch QA Environment"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidr_blocks
    description     = "Allow HTTPS traffic from private subnets"
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidr_blocks
    description     = "Placeholder for future configuration"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"  # All protocols
    cidr_blocks     = var.allowed_cidr_blocks
    description     = "Allow all outbound traffic"
  }

  tags = {
    Backup       = "Required"
    CostCenter   = "Engineering"
    Environment  = "qa"
    ManagedBy    = "terraform"
    Name         = "go-bharat-qa-elasticsearch-sg"
    Owner        = "DevOps Team"
    Project      = "go-bharat"
  }
}

## Redis Security Group
resource "aws_security_group" "redis" {
  name_prefix = "${local.sg_names.redis}-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Redis cluster"

  ingress {
    description = "Redis from ECS"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = merge(local.common_tags, {
    Name = local.sg_names.redis
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Kafka Security Group
resource "aws_security_group" "kafka" {
  name_prefix = "${local.sg_names.kafka}-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Kafka cluster"

  # Kafka broker communication
  ingress {
    description = "Kafka broker from ECS and internal"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Zookeeper communication
  ingress {
    description = "Zookeeper client"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Zookeeper peer communication
  ingress {
    description = "Zookeeper peer"
    from_port   = 2888
    to_port     = 2888
    protocol    = "tcp"
    self        = true
  }

  # Zookeeper leader election
  ingress {
    description = "Zookeeper leader election"
    from_port   = 3888
    to_port     = 3888
    protocol    = "tcp"
    self        = true
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # JMX monitoring (optional)
  ingress {
    description = "JMX monitoring"
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.sg_names.kafka
  })

  lifecycle {
    create_before_destroy = true
  }
}
