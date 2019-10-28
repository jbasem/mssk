resource "aws_ecs_cluster" "ecs" {
  name = local.app_name_prefix

  setting {
    name = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}