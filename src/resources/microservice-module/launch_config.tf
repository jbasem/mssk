module "ssh_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.4.0"
  namespace              = "${var.base_app_name}"
  stage                  = "${var.ms_name}"
  name                   = "${var.environment}-1"
  
  ssh_public_key_path   = "${local.output_meta_files_path}/ec2_key"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

resource "aws_launch_configuration" "lc" {
  name_prefix = "${local.ms_name_prefix}-${var.ec2_instance_type}-"
  image_id      = local.amz_optimized_ecs_image_id
  instance_type = var.ec2_instance_type
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance_profile.name}"
  security_groups = ["${module.ec2_sg.this_security_group_id}", local.consul_cluster_ec2_sg.id]
  key_name = "${module.ssh_key_pair.key_name}"

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
# Register instances with cluster
echo ECS_CLUSTER=${local.base_app_name_prefix} >> /etc/ecs/ecs.config

# Custom instance attributes... 
# "ms_name" will be used in the task placement constraints, to reserve the instance for tasks of this microservice only.
echo ECS_INSTANCE_ATTRIBUTES={ \"ms_name\" : \"${local.ms_name_prefix}\" } >> /etc/ecs/ecs.config
EOF

}
