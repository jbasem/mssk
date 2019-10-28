locals {
  consul_cluster_name_prefix = "${var.app_name}-consul-${var.environment}" # WARNING: Changing the name format here could break the tool (components in the microservices module use this name format.. needs to be changed in that case)
  consul_cluster_tag_key = "consul-cluster"
  consul_cluster_tag_value = "${local.consul_cluster_name_prefix}"
  consul_cluster_server_name_prefix = "${local.consul_cluster_name_prefix}-server"
  consul_cluster_client_name_prefix = "${local.consul_cluster_name_prefix}-client"
}


resource "aws_cloudwatch_log_group" "consul_log_group" {
  name              = "${local.consul_cluster_name_prefix}"
  retention_in_days = "${var.consul_log_group_retention_in_days}"

  tags = local.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2, Launch Configs & AutoScaling Group
# ---------------------------------------------------------------------------------------------------------------------


module "consul_server_ssh_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.4.0"
  name                   = "${local.consul_cluster_name_prefix}-server-ec2-key"
  
  ssh_public_key_path   = "${local.output_meta_files_path}/consul_server_ec2_key"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

resource "aws_launch_configuration" "consul_server_lc" {
  name_prefix = "${local.consul_cluster_server_name_prefix}-${var.consul_server_ec2_instance_type}-"
  image_id      = local.amz_optimized_ecs_image_id
  instance_type = var.consul_server_ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.consul_server_ec2_instance_profile.name
  security_groups = [module.consul_cluster_ec2_sg.this_security_group_id, module.consul_server_ec2_sg.this_security_group_id]
  key_name = "${module.consul_server_ssh_key_pair.key_name}"

  lifecycle {
    create_before_destroy = true
  }

      user_data = <<EOF
#!/bin/bash
# Register instances with cluster
echo ECS_CLUSTER=${local.app_name_prefix} >> /etc/ecs/ecs.config

# Custom instance attributes... will be used in the task placement constraints, to reserve the instance to consul servers only
echo ECS_INSTANCE_ATTRIBUTES={ \"ms_name\" :\"consul-server\" } >> /etc/ecs/ecs.config
EOF

}

module "consul_server_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  # Launch configuration
  create_lc = false # disables auto creation of launch configuration
  launch_configuration = "${aws_launch_configuration.consul_server_lc.name}" # Use the existing launch configuration
  name = "${local.consul_cluster_server_name_prefix}-autoscaling" # EC2 instance name

  # Auto scaling group
  asg_name                  = "${local.consul_cluster_server_name_prefix}-ecs-asg"
  vpc_zone_identifier       = local.public_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = "${var.consul_server_asg_health_check_grace_period}"
  min_size                  = "${var.consul_server_asg_min_size}"
  max_size                  = "${var.consul_server_asg_max_size}"
  desired_capacity          = "${var.consul_server_asg_desired_capacity}"
  wait_for_capacity_timeout = 0 # Terraform doesn't need to wait for capacity to be reached!

  tags = [
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "App"
      value               = "${local.app_name_prefix}"
      propagate_at_launch = true
    },
    {
      key                 = local.consul_cluster_tag_key
      value               = local.consul_cluster_tag_value
      propagate_at_launch = true
    }, 
  ]
}


# ---------------------------------------------------------------------------------------------------------------------
# Services and Task Definitions
# ---------------------------------------------------------------------------------------------------------------------


#
## Consul Servers
#

data "template_file" "consul_server_container_def" {
  template = file("${path.module}/resources/consul_server_container_def.json")

  vars = {
    region    = local.region
    log_group = local.consul_cluster_name_prefix
    consul_tag_key = local.consul_cluster_tag_key
    consul_tag_value = local.consul_cluster_tag_value
    inital_nodes_num= var.consul_server_asg_desired_capacity
  }
}

resource "aws_ecs_task_definition" "consul_server_task_def" {
  family = "${local.consul_cluster_server_name_prefix}"
  network_mode = "host"
  requires_compatibilities = ["EC2"]

  container_definitions = "${data.template_file.consul_server_container_def.rendered}"
}

resource "aws_ecs_service" "consul_server_service" {
  name = "${local.consul_cluster_server_name_prefix}"
  cluster = local.main_ecs.arn # Main ECS
  task_definition = aws_ecs_task_definition.consul_server_task_def.arn

  scheduling_strategy = "DAEMON"
  deployment_minimum_healthy_percent = 40

  
  # only deploy tasks on servers reserved for consul-server
  placement_constraints {   
    type = "memberOf"
    expression = "attribute:ms_name == consul-server"
  }

  # avoid multiple task on the same instance!
  placement_constraints {   
    type = "distinctInstance"
  }
}



#
## Consul Clients
#

data "template_file" "consul_client_container_def" {
  template = file("${path.module}/resources/consul_client_container_def.json")

  vars = {
    region    = local.region
    log_group = local.consul_cluster_name_prefix
    consul_tag_key = local.consul_cluster_tag_key
    consul_tag_value = local.consul_cluster_tag_value
  }
}

resource "aws_ecs_task_definition" "consul_client_task_def" {
  family = "${local.consul_cluster_client_name_prefix}"
  network_mode = "host"
  requires_compatibilities = ["EC2"]

  container_definitions = "${data.template_file.consul_client_container_def.rendered}"
}

resource "aws_ecs_service" "consul_client_service" {
  name = "${local.consul_cluster_client_name_prefix}"
  cluster = local.main_ecs.arn # Main ECS
  task_definition = aws_ecs_task_definition.consul_client_task_def.arn

  scheduling_strategy = "DAEMON"
  deployment_minimum_healthy_percent = 40


  # do not run consul client on instances reserved for consul server.. (i.e. run on all other instances in the cluster)
  placement_constraints {   
    type = "memberOf"
    expression = "not(attribute:ms_name == consul-server)"
  }

  # avoid multiple task on the same instance!
  placement_constraints {   
    type = "distinctInstance"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------------------------------------------------

# Applied to all instances in the consul cluster (i.e. all servers and clients)...
# should control consul related rules only...
module "consul_cluster_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> v3.1.0"

  name        = "${local.consul_cluster_name_prefix}-ec2-sg"
  description = "Security group for all Consul Cluster EC2 nodes (all servers and clients) to allow Consul required port rules" # port rules will be attached in another module below
  vpc_id      = local.vpc_id

  # Allow all rules for all protocols (outbound)
  egress_rules = ["all-all"]

  tags = local.tags
}

# Add Consul required specific ports and rules to Consul cluster instances
module "consul_cluster_sg_rules" {
  source = "git::git@github.com:hashicorp/terraform-aws-consul.git//modules/consul-security-group-rules?ref=v0.7.3"
  security_group_id                    = module.consul_cluster_ec2_sg.this_security_group_id

  # to allow inbound traffic to Consul required ports from external IPs (i.e. another consul cluster or something)
  allowed_inbound_cidr_blocks          = var.consul_cluster_ec2_ports_external_cidr_blocks
}


# Security group to configure general rules for EC2 instances running Cluster Servers.
module "consul_server_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> v3.1.0"

  name        = "${local.consul_cluster_name_prefix}-server-ec2-sg"
  description = "Security group for Consul server nodes to allow ssh connections"
  vpc_id      = local.vpc_id

  ingress_cidr_blocks = var.consul_server_ec2_ssh_inbound_cidr_blocks
  ingress_rules = ["ssh-tcp"]

  # Allow all rules for all protocols (outbound)
  egress_rules = ["all-all"]

  tags = local.tags
}



# ---------------------------------------------------------------------------------------------------------------------
# Roles
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "consul_server_ec2_instance_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "consul_server_ec2_instance_role" {
  name_prefix = "consul-server-ec2-instance-role"
  assume_role_policy = "${data.aws_iam_policy_document.consul_server_ec2_instance_policy.json}"

  # avoid cyclic dependencies on destroy
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "consul_server_ec2_instance_role_attachment" {
  role = "${aws_iam_role.consul_server_ec2_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "consul_server_instance_role_quick_sight_attachment" {
  role = "${aws_iam_role.consul_server_ec2_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSQuickSightDescribeRDS"
}


# Attach Consul specific needed policies (auto discover instances, describe tags, describe auto scaling groups)
module "iam_policies" {
  source = "git::git@github.com:hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.3"
  iam_role_id =  aws_iam_role.consul_server_ec2_instance_role.id
}


resource "aws_iam_instance_profile" "consul_server_ec2_instance_profile" {
  name_prefix = "consul-server-ec2-instance-profile"
  path = "/"
  role = aws_iam_role.consul_server_ec2_instance_role.id

   # avoid cyclic dependencies on destroy
  lifecycle {
    create_before_destroy = true
  }
}








# # ---------------------------------------------------------------------------------------------------------------------
# # AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT AMI
# # This repo contains a CircleCI job that automatically builds and publishes the latest AMI by building the Packer
# # template at /examples/consul-ami upon every new release. The Terraform data source below automatically looks up the
# # latest AMI so that a simple "terraform apply" will just work without the user needing to manually build an AMI and
# # fill in the right value.
# #
# # !! WARNING !! These exmaple AMIs are meant only convenience when initially testing this repo. Do NOT use these example
# # AMIs in a production setting because it is important that you consciously think through the configuration you want
# # in your own production AMI.
# # ---------------------------------------------------------------------------------------------------------------------
# data "aws_ami" "consul" {
#   most_recent = true

#   # If we change the AWS Account in which test are run, update this value.
#   owners = ["562637147889"]

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   filter {
#     name   = "is-public"
#     values = ["true"]
#   }

#   filter {
#     name   = "name"
#     values = ["consul-ubuntu-*"]
#   }
# }

