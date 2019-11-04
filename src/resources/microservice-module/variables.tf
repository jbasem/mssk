

### Base app configs (must be consistent with base app!!)

variable "base_app_name" { 
	type = string 
  default = "ms-app"
}

variable "environment" {
  type = string
  default = "qa"
}


### MS Configs

variable "ms_name" { 
  type = string 
  default = "main"
}

variable "url_base_path" {
  type = string
  default = "/main"
}

variable "log_group_retention_in_days" {
  type = number
  default = 7
}


## DB

variable "db_apply_immediately" {
  type = bool
  default = true
}

variable "db_engine" {
  type = string
  default = "mysql"
}

variable "db_engine_version_major" {
  type = string
  default = "8.0"
}

variable "db_engine_version_minor" {
  type = string
  default = "16"
}

variable "db_instance_class" {
  type = string
  default = "db.t2.micro"
}

variable "db_replicas_count" {
  type = number
  default = 1
}

variable "db_replica_instance_class" {
  type = string
  default = "db.t2.micro"
}

# in gigabytes
variable "db_allocated_storage" {
  type = number
  default = 5
}

variable "db_username" {
  type = string
  default = "root"
}

variable "db_deletion_protection" {
  type = bool
  default = false
}

variable "db_storage_encrypted" {
  type = bool
  default = false
}

variable "db_port" {
  type = number
  default = 3306
}

variable "db_maintenance_window" {
  type = string
  default = "Mon:00:00-Mon:03:00"
}

variable "db_backup_window" {
  type = string
  default = "03:00-06:00"
}

# days to keep the backup files for.. must be between 1 and 35 (not zero because this is for master db)
variable "db_backup_retention_period_in_days" {
  type = number
  default = 7
}

variable "db_log_types" {
  type = list(string)
  default = ["general", "error", "slowquery"]
}


## Redis

variable "redis_instance_class" {
  type = string
  default = "cache.t2.micro"
}

variable "redis_port" {
  type = number
  default = 6379
}

variable "redis_engine_version" {
  type = string
  default = "4.0.10"
}

variable "redis_maintenance_window" {
  type = string
  default = "Mon:00:00-Mon:03:00"
}


## Security groups

# IPs in this list would be able to SSH to all server instances.
variable "ec2_ssh_inbound_cidr_blocks" {
  type    = list(string)
  default = []
}


## ECS task and service

variable "ec2_instance_type" {
  type = string
  default = "t2.micro"
}

variable "asg_min_size" {
  type = number
  default = 1
}

variable "asg_max_size" {
  type = number
  default = 3
}

variable "asg_desired_capacity" {
  type = number
  default = 2
}

variable "asg_health_check_grace_period" {
  type = number
  default = 300
}

# possible values: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold.
variable "asg_alarm_comparison_operator" {
  type = string
  default = "GreaterThanOrEqualToThreshold"
}

variable "asg_alarm_threshold" {
  type = number
  default = 80
}

variable "asg_alarm_evaluation_periods" {
  type = number
  default = 2
}

variable "asg_alarm_period" {
  type = number
  default = 120
}

variable "task_def_soft_memory" {
  type = number
  default = 512
}

variable "ecs_service_deployment_minimum_healthy_percent" {
  type = number
  default = 20
}

variable "ecs_task_deregistration_delay" {
  type = number
  default = 60
}

variable "container_port" {
  type = number
  default = 8080
}

variable "health_check_path" {
  type = string
  default = "/health"
}

variable "health_check_interval" {
  type = string
  default = 60
}

variable "health_check_timeout" {
  type = string
  default = 30
}

variable "health_check_healthy_threshold" {
  type = string
  default = 3
}

variable "health_check_unhealthy_threshold" {
  type = string
  default = 3
}

variable "health_check_success_http_code" {
  type = string
  default = "200-299"
}



