# Application Load Balancer
resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = var.enable_deletion_protection && var.environment == "prod"

  tags = local.common_tags
}

# Target Groups for Microservices
resource "aws_lb_target_group" "restaurant" {
  name        = "gobharat-restaurant"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/restaurant/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharat-restaurant"
  })
}

resource "aws_lb_target_group" "communication" {
  name        = "gobharatapp-communication"
  port        = 8787
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/communication/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-communication"
  })
}

resource "aws_lb_target_group" "customer" {
  name        = "gobharatapp-customer"
  port        = 8585
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/customer/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-customer"
  })
}

resource "aws_lb_target_group" "datasyncservice" {
  name        = "gobharatapp-datasyncservice"
  port        = 9797
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/data-sync/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-datasyncservice"
  })
}

resource "aws_lb_target_group" "delivery" {
  name        = "gobharatapp-delivery"
  port        = 8686
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/partner/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-delivery"
  })
}

resource "aws_lb_target_group" "order" {
  name        = "gobharatapp-order"
  port        = 8383
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/order/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-order"
  })
}

resource "aws_lb_target_group" "payment" {
  name        = "gobharatapp-payment"
  port        = 8085
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/payment/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-payment"
  })
}

resource "aws_lb_target_group" "support_agent" {
  name        = "gobharatapp-support-agent"
  port        = 9191
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/support/orders/count"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-support-agent"
  })
}

resource "aws_lb_target_group" "api" {
  name        = "gobharatapp-api"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/gateway/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "gobharatapp-api"
  })
}

# Listeners
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.enable_https ? "443" : "80"
  protocol          = var.enable_https ? "HTTPS" : "HTTP"
  ssl_policy        = var.enable_https ? "ELBSecurityPolicy-TLS-1-2-2017-01" : null
  certificate_arn   = var.enable_https ? var.ssl_certificate_arn : null

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.customer.arn
      }
    }
  }
}

# HTTP to HTTPS redirect (if HTTPS is enabled)
resource "aws_lb_listener" "redirect" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener Rules for Microservices
resource "aws_lb_listener_rule" "restaurant_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.restaurant.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/restaurant/*", "/restaurant/*"]
    }
  }
}

resource "aws_lb_listener_rule" "order_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.order.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/order/*", "/order/*"]
    }
  }
}

resource "aws_lb_listener_rule" "payment_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 300

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.payment.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/payment/*", "/payment/*"]
    }
  }
}

resource "aws_lb_listener_rule" "communication_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 400

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.communication.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/communication/*", "/communication/*"]
    }
  }
}

resource "aws_lb_listener_rule" "delivery_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 500

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.delivery.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/partner/*", "/partner/*", "/delivery/*"]
    }
  }
}

resource "aws_lb_listener_rule" "support_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 600

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.support_agent.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/support/*", "/support/*"]
    }
  }
}

resource "aws_lb_listener_rule" "datasync_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 700

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.datasyncservice.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/data-sync/*", "/data-sync/*"]
    }
  }
}

resource "aws_lb_listener_rule" "api_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 800

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.api.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/gateway/*"]
    }
  }
}