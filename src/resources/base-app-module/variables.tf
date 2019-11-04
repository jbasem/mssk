### General project inputs

variable "app_name" { 
	type = string 
  default = "ms-app"
}

variable "environment" {
	type = string
  default = "qa"
}


### VPC inputs
variable "vpc_configs" {
  type = object({
    vpc_cidr = string
    azs = list(string)
    public_subnets_cidr = list(string)
    private_subnets_cidr = list(string)
  })   
  default = {
    vpc_cidr = "10.0.0.0/16"
    azs = ["us-east-1a", "us-east-1b"] # must be within the same region
    # the number of public and private subnets much match number of availability zones
    public_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets_cidr = ["10.0.101.0/24", "10.0.102.0/24"]
  }
}

### Security groups

# This is for the Application Load Balancer, which is the main entry point for the system (internet facing). So it must always be 0.0.0.0/0 (= anywhere), 
# unless if you don't want the application to be publically reachable.
variable "alb_inbound_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"] 
}

# possible values: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold.
variable "alb_active_connections_alarm_comparison_operator" {
  type = string
  default = "GreaterThanOrEqualToThreshold"
}

variable "alb_active_connections_alarm_threshold" {
  type = number
  default = 1000
}

variable "alb_active_connections_alarm_evaluation_periods" {
  type = number
  default = 2
}

variable "alb_active_connections_alarm_period" {
  type = number
  default = 120
}


### Consul

variable "consul_server_ec2_instance_type" {
  type = string
  default = "t2.micro"
}

variable "consul_server_asg_health_check_grace_period" {
  type = number
  default = 300
}

variable "consul_server_asg_min_size" {
  type = number
  default = 1
}

variable "consul_server_asg_max_size" {
  type = number
  default = 3
}

variable "consul_server_asg_desired_capacity" {
  type = number
  default = 2
}

variable "consul_log_group_retention_in_days" {
  type = number
  default = 5
}

# IPs in this list would be able to SSH to Consul Server instances.
variable "consul_server_ec2_ssh_inbound_cidr_blocks" {
  type = list(string)
  default = []
}

# IPs in this list would be able to allow external calls to Consul Server default ports (8500, 8400....etc) through TCP & UDP.
variable "consul_cluster_ec2_ports_external_cidr_blocks" {
  type = list(string)
  default = []
}



