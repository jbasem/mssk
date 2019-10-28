locals {
  consul_cluster_tag_key = "consul-cluster"
  consul_cluster_tag_value = "${local.consul_cluster_name_prefix}"
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  # Launch configuration
  create_lc = false # disables auto creation of launch configuration
  launch_configuration = "${aws_launch_configuration.lc.name}" # Use the existing launch configuration
  name = "${local.ms_name_prefix}-autoscaling" # EC2 Instance name

  target_group_arns = ["${aws_alb_target_group.tg.arn}"]


  # Auto scaling group
  asg_name                  = "${local.ms_name_prefix}-ecs-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all_public.ids
  health_check_type         = "EC2"
  health_check_grace_period = "${var.asg_health_check_grace_period}"
  min_size                  = "${var.asg_min_size}"
  max_size                  = "${var.asg_max_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  wait_for_capacity_timeout = 0 # Terraform doesn't need to wait for capacity to be reached!

  tags = [
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "App"
      value               = "${var.base_app_name}"
      propagate_at_launch = true
    },
    {
      key                 = "Service"
      value               = "${var.ms_name}"
      propagate_at_launch = true
    },
    {
      key                 = local.consul_cluster_tag_key
      value               = local.consul_cluster_tag_value
      propagate_at_launch = true
    },
  ]
}
