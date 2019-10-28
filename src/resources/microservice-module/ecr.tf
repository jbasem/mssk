module "ecr" {
  source                 = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=0.7.0"
  namespace              = "${var.base_app_name}"
  stage                  = "${var.ms_name}"
  name                   = "${var.environment}"

  tags = local.tags
}