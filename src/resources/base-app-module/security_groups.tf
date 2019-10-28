module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> v3.1.0"

  name        = "${local.app_name_prefix}-alb-sg"
  description = "Security group for ALB with HTTP 80, HTTPS 443"
  vpc_id      = local.vpc_id

  ingress_cidr_blocks = "${var.alb_inbound_cidr_blocks}"
  ingress_rules = ["http-80-tcp", "https-443-tcp"]

  # Allow all rules for all protocols (outbound)
  egress_rules = ["all-all"]

  tags = local.tags
}
