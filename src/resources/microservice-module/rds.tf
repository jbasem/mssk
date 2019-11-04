#######################
#### Master DB 
#######################

module "master_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = local.ms_name_prefix # instance identifier
  apply_immediately = var.db_apply_immediately

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "${var.db_engine}"
  engine_version    = "${var.db_engine_version_major}.${var.db_engine_version_minor}"


  instance_class    = "${var.db_instance_class}"
  allocated_storage = "${var.db_allocated_storage}"

  # kms_key_id        = "arm:aws:kms:<region>:<accound id>:key/<kms key id>"
  name     = "${var.ms_name}" # db name
  username = "${var.db_username}"
  port     = "${var.db_port}"

  # Outside changes to the password won't be tracked! So you can changed it after creation directly from AWS console or CLI.
  password = "${local.db_initial_password}" 

  # backup and maintenance
  maintenance_window = "${var.db_maintenance_window}"
  backup_window      = "${var.db_backup_window}"
  backup_retention_period = "${var.db_backup_retention_period_in_days}"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.base_app_name}-${var.ms_name}-${var.environment}"
  
  # DB parameter group
  family = "${var.db_engine}${var.db_engine_version_major}"
  # DB option group
  major_engine_version = "${var.db_engine_version_major}"

  deletion_protection = "${var.db_deletion_protection}"
  storage_encrypted = "${var.db_storage_encrypted}"

  tags = local.tags

  # security groups
  vpc_security_group_ids = ["${module.rds_sg.this_security_group_id}"]

  # Enhanced Monitoring
  monitoring_interval = "30"
  monitoring_role_arn  = aws_iam_role.rds_enhanced_monitoring.arn

  enabled_cloudwatch_logs_exports = "${var.db_log_types}"

  # DB subnet groups
  subnet_ids = data.aws_subnet_ids.all_private.ids
  multi_az = true
  publicly_accessible = false

  iam_database_authentication_enabled = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]
}



#######################
#### Read Replicas
#######################


resource "aws_db_instance" "read_replica" {
  replicate_source_db = module.master_db.this_db_instance_id

  count = "${var.db_replicas_count}"
  identifier = "${local.ms_name_prefix}-replica-${count.index}"
  
  # Username and password should not be set for replicas
  instance_class    = "${var.db_replica_instance_class}"
  port     = "${var.db_port}"

  # security groups
  vpc_security_group_ids = ["${module.rds_sg.this_security_group_id}"]
  maintenance_window = "${var.db_maintenance_window}"

  # replicas cannot be multi_az
  multi_az = false

  # disable backups to create DB faster
  backup_retention_period = 0
  skip_final_snapshot = true
}


###################
## Alarm Metrics
###################

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${local.ms_name_prefix}-rds-read-latency"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  comparison_operator = "${var.db_read_latency_alarm_comparison_operator}"
  threshold           = "${var.db_read_latency_alarm_threshold}"
  evaluation_periods  = "${var.db_read_latency_alarm_evaluation_periods}"
  period              = "${var.db_read_latency_alarm_period}"

  dimensions = {
    DBInstanceIdentifier = local.ms_name_prefix # instance identifier
  }

  alarm_description = "This metric monitors rds read latency"

  tags = local.tags
}


resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "${local.ms_name_prefix}-rds-write-latency"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  comparison_operator = "${var.db_write_latency_alarm_comparison_operator}"
  threshold           = "${var.db_write_latency_alarm_threshold}"
  evaluation_periods  = "${var.db_write_latency_alarm_evaluation_periods}"
  period              = "${var.db_write_latency_alarm_period}"

  dimensions = {
    DBInstanceIdentifier = local.ms_name_prefix # instance identifier
  }

  alarm_description = "This metric monitors rds write latency"

  tags = local.tags
}
