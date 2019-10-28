terraform {
  required_version = ">= 0.12"
}

locals {
  app_name_prefix = "${var.app_name}-${var.environment}"
  
  vpc_cidr = var.vpc_configs.vpc_cidr
  vpc_id = "${module.vpc_and_subnets.vpc_id}"
  
  azs = var.vpc_configs.azs
  public_subnets_cidr = var.vpc_configs.public_subnets_cidr
  private_subnets_cidr = var.vpc_configs.private_subnets_cidr
  public_subnet_ids = "${module.vpc_and_subnets.public_subnets}"
  private_subnet_ids = "${module.vpc_and_subnets.private_subnets}"

  amz_optimized_ecs_image_id = "${data.aws_ami.optimized_ecs.id}"
  main_ecs = aws_ecs_cluster.ecs

  output_meta_files_path = "${path.root}/meta_outputs"
  tags = {
    Environment = "${var.environment}"
    App = "${var.app_name}"
  }

  region = data.aws_region.current.name
}

# Data sources

data "aws_region" "current" {}

# Amazon Optimized-ECS AMI

data "aws_ami" "optimized_ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # Amazon
}