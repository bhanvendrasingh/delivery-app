# Launch Template for ECS instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${local.name_prefix}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_types[0]
  key_name      = aws_key_pair.main.key_name

  vpc_security_group_ids = [aws_security_group.ecs.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    cluster_name = aws_ecs_cluster.main.name
    environment  = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-ecs-instance"
    })
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  name                = "${local.name_prefix}-ecs-asg"
  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns = [
  aws_lb_target_group.restaurant.arn,
  aws_lb_target_group.communication.arn,
  aws_lb_target_group.customer.arn,
  aws_lb_target_group.datasyncservice.arn,
  aws_lb_target_group.delivery.arn,
  aws_lb_target_group.order.arn,
  aws_lb_target_group.payment.arn,
  aws_lb_target_group.support_agent.arn,
]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.spot_instances.min
  max_size         = var.spot_instances.max
  desired_capacity = var.spot_instances.min

  capacity_rebalance = true
  force_delete      = true

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.environment == "prod" ? 1 : 0
      on_demand_percentage_above_base_capacity = var.environment == "prod" ? 25 : 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs.id
        version           = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for ECS optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${local.name_prefix}-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = local.common_tags
}