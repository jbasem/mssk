data "aws_iam_policy_document" "ecs_instance_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name_prefix = "ecs-instance-role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance_policy.json}"

  # avoid cyclic dependencies on destroy
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ec2_role_attachment" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_rds_role_attachment" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSQuickSightDescribeRDS"
}


# Attach Consul specific needed policies (auto discover instances, describe tags, describe auto scaling groups).. Needed for the EC2 instance since it will be running the consul client agent
module "iam_policies" {
  source = "git::git@github.com:hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.3"
  iam_role_id =  aws_iam_role.ecs_instance_role.id
}


resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name_prefix = "ecs-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs_instance_role.id}"
  
  # avoid cyclic dependencies on destroy
  lifecycle {
    create_before_destroy = true
  }
}





data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name_prefix = "ecs-service-role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_policy.json}"

  # avoid cyclic dependencies on destroy
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attachment" {
  role = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}





data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json

  # avoid cyclic dependencies on destroy
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}