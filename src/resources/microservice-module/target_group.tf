resource "aws_alb_target_group" "tg" {
  name = "${local.ms_name_prefix}-tg"
  port = var.container_port
  protocol = "HTTP"
  vpc_id = local.vpc_id
  deregistration_delay = var.ecs_task_deregistration_delay

  health_check {
    enabled = true
    path = "${var.url_base_path}${var.health_check_path}"
    interval = var.health_check_interval
    timeout = var.health_check_timeout
    healthy_threshold = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher = var.health_check_success_http_code
  }

  tags = local.tags
}

# attach it to loadbalancer
resource "aws_lb_listener_rule" "tg_rule" {
  listener_arn = "${local.alb_listner.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.tg.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["${var.url_base_path}/*"]
  }
}
