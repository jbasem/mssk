# #######
# NOTE:
# - Changes to the task defention here will create a new task revision, but will NOT update the service to use the newly created revison.
# This is because the service resource is set to ignore task_def changes.. Read the comment in the lifecycle block ofservice resource below...
# If you want the service to update itself with the new task revision, just comment out the ignore_changes line in the service resource below!
##########
resource "aws_ecs_task_definition" "task_def" {
  family = "${local.ms_name_prefix}"
  network_mode = "host"
  requires_compatibilities = ["EC2"]

  # since this is in host mode, so container ports would be exposed directly to host instance ports, hence must be the same..
  container_definitions = <<EOF
  [
    {
      "name": "${local.ms_name_prefix}",
      "image": "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.ms_name_prefix}:latest",
      "memoryReservation": ${var.task_def_soft_memory},
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${var.container_port},
          "hostPort": ${var.container_port}
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${local.region}",
          "awslogs-group": "${local.ms_name_prefix}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "environment": [
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "${var.environment}"
        }
      ]
    }
  ]
  EOF
}

resource "aws_ecs_service" "service" {
  name = "${local.ms_name_prefix}"
  cluster = local.ecs_cluster.arn
  iam_role = "${aws_iam_role.ecs_service_role.name}"
  task_definition = aws_ecs_task_definition.task_def.arn

  scheduling_strategy = "DAEMON"
  deployment_minimum_healthy_percent = var.ecs_service_deployment_minimum_healthy_percent

  load_balancer {
    target_group_arn = "${aws_alb_target_group.tg.arn}"
    container_name   = "${local.ms_name_prefix}"
    container_port   = "${var.container_port}"
  }

  # only deploy tasks on servers reserved for this microservice
  placement_constraints {   
    type = "memberOf"
    expression = "attribute:ms_name == ${local.ms_name_prefix}"
  }

  # avoid multiple task on the same instance!
  placement_constraints {   
    type = "distinctInstance"
  }

  lifecycle {
    # ignore external changes to the selected task_defintion after first creation!
    # this is because normally CI/CD pipelines automatically create a new task revision on each deploy and update the to use it. 
    # Hence, the task defention in Terraform would be out of date each time!
    # If you want to apply a change to task_defention in terraform after creation, just update the task revision above as needed,,
    # then comment out the line below.... Put the lines back on when you are done...
    # ignore_changes        = ["task_definition"]
  }
}