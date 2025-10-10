# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  tags = local.common_tags
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "main" {
  name = "${local.name_prefix}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

# CloudWatch Log Groups for Microservices
resource "aws_cloudwatch_log_group" "microservices" {
  for_each = local.microservices
  
  name              = "/ecs/${local.name_prefix}/${each.value}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# ECS Task Definitions for Microservices
resource "aws_ecs_task_definition" "microservices" {
  for_each = local.microservices

  family                   = "${local.name_prefix}-${each.value}"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.applications[each.key].cpu
  memory                   = var.applications[each.key].memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = each.value
      # image = var.ecr_repositories[each.value] != "" ? "${var.ecr_repositories[each.key]}:${var.applications[each.key].image_tag}" : "${aws_ecr_repository.microservices[each.key].repository_url}:${var.applications[each.key].image_tag}"
      image = "692859922629.dkr.ecr.ap-south-2.amazonaws.com/gobharat/temp-gobharat:${each.value}"
      cpu          = var.applications[each.key].cpu
      memory       = var.applications[each.key].memory
      essential    = true
      
      portMappings = [
        {
          containerPort = var.applications[each.key].port
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.microservices[each.key].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "SERVER_PORT"
          value = tostring(var.applications[each.key].port)
        },
        {
          name  = "SERVICE_NAME"
          value = each.value
        }
      ]

      ## Note: Springboot will use env over application.properties 
      secrets = [
        {
          name      = "SPRING_DATA_REDIS_HOST"
          valueFrom = aws_ssm_parameter.redis_endpoint.arn
        },
        {
          name      = "MONGODB_PASSWORD"
          valueFrom = aws_ssm_parameter.mongodb_password.arn
        },
        {
          name      = "MONGODB_CONNECTION_STRING"
          valueFrom = aws_ssm_parameter.mongodb_connection_string.arn
        },
        {
          name      = "MONGODB_USERNAME"
          valueFrom = aws_ssm_parameter.mongodb_username.arn
        },
        {
          name      = "MONGODB_ENDPOINT"
          valueFrom = aws_ssm_parameter.mongodb_endpoint.arn
        }
      ]
    }
  ])

  tags = local.common_tags
}

# ECS Services for Microservices
resource "aws_ecs_service" "communication" {
  name            = "${local.name_prefix}-communication-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["communication-service"].arn
  desired_count   = var.applications["communication-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.communication.arn
    container_name   = "communication-service"
    container_port   = var.applications["communication-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "delivery" {
  name            = "${local.name_prefix}-delivery-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["delivery-partner-service"].arn
  desired_count   = var.applications["delivery-partner-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.delivery.arn
    container_name   = "delivery-partner-service"
    container_port   = var.applications["delivery-partner-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "payment" {
  name            = "${local.name_prefix}-payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["payment-service"].arn
  desired_count   = var.applications["payment-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payment.arn
    container_name   = "payment-service"
    container_port   = var.applications["payment-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "support_agent" {
  name            = "${local.name_prefix}-support-agent-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["support-agent-service"].arn
  desired_count   = var.applications["support-agent-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.support_agent.arn
    container_name   = "support-agent-service"
    container_port   = var.applications["support-agent-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "data_sync" {
  name            = "${local.name_prefix}-data-sync-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["data-sync-service"].arn
  desired_count   = var.applications["data-sync-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.datasyncservice.arn
    container_name   = "data-sync-service"
    container_port   = var.applications["data-sync-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "order" {
  name            = "${local.name_prefix}-order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["order-service"].arn
  desired_count   = var.applications["order-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.order.arn
    container_name   = "order-service"
    container_port   = var.applications["order-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "restaurant" {
  name            = "${local.name_prefix}-restaurant-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["restaurant-service"].arn
  desired_count   = var.applications["restaurant-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.restaurant.arn
    container_name   = "restaurant-service"
    container_port   = var.applications["restaurant-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "customer" {
  name            = "${local.name_prefix}-customer-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["customer-service"].arn
  desired_count   = var.applications["customer-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.customer.arn
    container_name   = "customer-service"
    container_port   = var.applications["customer-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}

resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api-gateway-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservices["api-gateway-service"].arn
  desired_count   = var.applications["api-gateway-service"].replicas
  
  health_check_grace_period_seconds = 120

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight           = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-gateway-service"
    container_port   = var.applications["api-gateway-service"].port
  }

  depends_on = [aws_lb_listener.main]
  tags = local.common_tags
}