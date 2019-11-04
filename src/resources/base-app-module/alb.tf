locals {
  alb_name = "${local.app_name_prefix}-alb" # WARNING: Changing the name format here could break the tool (components in the microservices module use this name format.. needs to be changed in that case)
  logs_bucket_name = "${local.app_name_prefix}-logs"
}

module "alb_logs_s3_bucket" {
  source    = "git::https://github.com/cloudposse/terraform-aws-lb-s3-bucket.git?ref=0.2.0"
  name      = local.logs_bucket_name
  region    = "${local.region}"

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 4.0"

  load_balancer_name            = local.alb_name
  vpc_id                        = local.vpc_id
  subnets                       = local.public_subnet_ids
  security_groups               = ["${module.alb_sg.this_security_group_id}"]

  log_bucket_name               = local.logs_bucket_name
  log_location_prefix           = "${local.alb_name}-logs"

  tags                          = local.tags
  
  http_tcp_listeners            = [
    {
      port              = "80"
      protocol          = "HTTP"
    }
  ]
  http_tcp_listeners_count      = "1"

  target_groups                 = [
    {
      name = "${local.app_name_prefix}-default-tg"
      backend_protocol = "HTTP"
      backend_port = 80
    }
  ]
  target_groups_count           = "1"
}

resource "aws_cloudwatch_metric_alarm" "alb_active_connections" {
  alarm_name          = "${local.app_name_prefix}-alb-active-connections"
  metric_name         = "ActiveConnectionCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  comparison_operator = "${var.alb_active_connections_alarm_comparison_operator}"
  threshold           = "${var.alb_active_connections_alarm_threshold}"
  evaluation_periods  = "${var.alb_active_connections_alarm_evaluation_periods}"
  period              = "${var.alb_active_connections_alarm_period}"

  dimensions = {
    LoadBalancer = "${module.alb.load_balancer_arn_suffix}"
  }

  alarm_description = "This metric monitors ALB active connections"

  tags = local.tags
}
