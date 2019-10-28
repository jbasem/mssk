terraform {
  required_version = ">= 0.12"
}

locals {
  region = data.aws_region.current.name
  base_app_name_prefix = "${var.base_app_name}-${var.environment}"
  ms_name_prefix = "${var.base_app_name}-${var.ms_name}-${var.environment}"
  consul_cluster_name_prefix = "${var.base_app_name}-consul-${var.environment}"

  vpc_id = "${data.aws_vpc.main_vpc.id}"
  alb = data.aws_alb.main_alb
  alb_listner = data.aws_lb_listener.alb_http_listner
  ecs_cluster = data.aws_ecs_cluster.ecs_cluster
  account_id = "${data.aws_caller_identity.current.account_id}"
  alb_sg = "${data.aws_security_group.alb_sg}"
  consul_cluster_ec2_sg = "${data.aws_security_group.consul_cluster_ec2_sg}"

  amz_optimized_ecs_image_id = "${data.aws_ami.optimized_ecs.id}"

  db_initial_password = "ChangeThisPassword!"
  tags = {
    App = "${var.base_app_name}"
    Service = "${var.ms_name}"
    Environment = "${var.environment}"
  }

  output_meta_files_path = "${path.root}/meta_outputs"
}


# meta output files
resource "local_file" "microservice_metadata" {
  content = <<EOF
# spring cloud RDS properties
cloud.aws.region.auto=true
cloud.aws.credentials.instanceProfile=true

cloud.aws.rds.${module.master_db.this_db_instance_id}.databaseName=${module.master_db.this_db_instance_name}
cloud.aws.rds.${module.master_db.this_db_instance_id}.username=${module.master_db.this_db_instance_username}
cloud.aws.rds.${module.master_db.this_db_instance_id}.password=${local.db_initial_password}
cloud.aws.rds.${module.master_db.this_db_instance_id}.readReplicaSupport=true

spring.jpa.show-sql = true
spring.jpa.hibernate.ddl-auto = update

# redis Config
spring.redis.host=${aws_elasticache_cluster.redis_db_cache.cache_nodes[0].address}
spring.redis.port=${aws_elasticache_cluster.redis_db_cache.cache_nodes[0].port}
EOF

  filename = "${local.output_meta_files_path}/application-${var.environment}.properties"
}


resource "local_file" "read_me" {
  content = <<EOF
* Generated components prefix: "${local.ms_name_prefix}"

* Microservice is registered with the main loadbalancer on path: /${var.ms_name}/*
Therefore, once the microservice is deployed, the APIs can be called through the load balancer DNS + the forward path, which is:
http://${local.alb.dns_name}/${var.ms_name}/<specific_api_path>

* Master DB (${local.ms_name_prefix}) is created with initial password: "${local.db_initial_password}".. 
You must change it directly from AWS console or CLI. Do not use terraform for that (it is unsecure because it will stay saved in terraform files)

* You can copy the "./application-${var.environment}.properties" file into the "resources" folder in you JAVA Spring Boot/Cloud project. 
EOF

  filename = "${local.output_meta_files_path}/README.md"
}


# main log group configs
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${local.ms_name_prefix}"
  retention_in_days = "${var.log_group_retention_in_days}"

  tags = local.tags
}

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

# Data sources to get execution required info (VPC, subnets, region...etc.)

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "main_vpc" {
  tags = {
    Environment = "${var.environment}"
    App = "${var.base_app_name}"
  }
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.main_vpc.id
}

data "aws_subnet_ids" "all_public" {
  vpc_id = data.aws_vpc.main_vpc.id

  tags = {
    Scope = "Public"
  }
}

data "aws_subnet_ids" "all_private" {
  vpc_id = data.aws_vpc.main_vpc.id

  tags = {
    Scope = "Private"
  }
}

data "aws_alb" "main_alb" {
  name = "${local.base_app_name_prefix}-alb"
}

data "aws_lb_listener" "alb_http_listner" {
  load_balancer_arn = "${data.aws_alb.main_alb.arn}"
  port              = 80
}

data "aws_security_group" "alb_sg" {
  vpc_id = data.aws_vpc.main_vpc.id
  
  tags = {
    Name = "${local.base_app_name_prefix}-alb-sg"
  }
}

data "aws_security_group" "consul_cluster_ec2_sg" {
  vpc_id = data.aws_vpc.main_vpc.id
  
  tags = {
    Name = "${local.consul_cluster_name_prefix}-ec2-sg"
  }
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = local.base_app_name_prefix
}




