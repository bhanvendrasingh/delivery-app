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
    cidr_blocks = ["0.0.0.0/0"]
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
    #   security_groups = [aws_security_group.alb.id]
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.sg_names.ecs
  })

  lifecycle {
    create_before_destroy = true
  }
}

# # MongoDB DocumentDB Security Group
# resource "aws_security_group" "mongodb" {
#   name_prefix = "${local.sg_names.mongodb}-"
#   vpc_id      = module.vpc.vpc_id
#   description = "Security group for MongoDB DocumentDB cluster"

#   ingress {
#     description     = "MongoDB from ECS"
#     from_port       = 27017
#     to_port         = 27017
#     protocol        = "tcp"
#     security_groups = [aws_security_group.ecs.id]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(local.common_tags, {
#     Name = local.sg_names.mongodb
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }