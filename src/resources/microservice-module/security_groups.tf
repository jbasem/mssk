## EC2 in ECS

module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> v3.1.0"

  name        = "${local.ms_name_prefix}-ec2-sg"
  description = "Security group for ECS with HTTP 80, HTTPS 443, SSH & Redis 6379 allowed connections"
  vpc_id      = local.vpc_id

  ingress_cidr_blocks = "${var.ec2_ssh_inbound_cidr_blocks}"
  ingress_rules = ["ssh-tcp"]

  # Allow all rules for all protocols (outbound)
  egress_rules = ["all-all"]

  tags = local.tags
}

resource "aws_security_group_rule" "allow_alb_to_ec2" {
  type            = "ingress"
  from_port       = "0"
  to_port         = "65535"
  protocol        = "tcp"
  description     = "Allow connections from the application load balancer to the dynamic ECS ports"
  source_security_group_id = "${local.alb_sg.id}"
  security_group_id = "${module.ec2_sg.this_security_group_id}"
}


## RDS

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> v3.1.0"

  name        = "${local.ms_name_prefix}-rds-sg"
  description = "Security group for RDS to allow ssh, and connections only from EC2 webservers in same vpc"
  vpc_id      = local.vpc_id

  # ingress_cidr_blocks = "${var.rds_ssh_inbound_cidr_blocks}"
  # ingress_rules = ["ssh-tcp"]

  # Allow all rules for all protocols (outbound)
  egress_rules = ["all-all"]

  tags = local.tags
}

resource "aws_security_group_rule" "allow_ec2_to_rds" {
  type            = "ingress"
  from_port       = "${var.db_port}"
  to_port         = "${var.db_port}"
  protocol        = "tcp"
  description     = "Allow connections from EC2 instances in VPC only"
  source_security_group_id = "${module.ec2_sg.this_security_group_id}"
  security_group_id = "${module.rds_sg.this_security_group_id}"
}


## Redis

module "redis_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> v3.1.0"

  name        = "${local.ms_name_prefix}-redis-sg"
  description = "Security group for Redis to allow ssh, and connections only from EC2 webservers in same vpc"
  vpc_id      = local.vpc_id

  # ingress_cidr_blocks = "${var.redis_ssh_inbound_cidr_blocks}"
  # ingress_rules = ["ssh-tcp"]

  # Allow all rules for all protocols (outbound)
  egress_rules = ["all-all"]

  tags = local.tags
}

resource "aws_security_group_rule" "allow_ec2_to_redis" {
  type            = "ingress"
  from_port       = "${var.redis_port}"
  to_port         = "${var.redis_port}"
  protocol        = "tcp"
  description     = "Allow connections from EC2 instances in VPC only"
  source_security_group_id = "${module.ec2_sg.this_security_group_id}"
  security_group_id = "${module.redis_sg.this_security_group_id}"
}


