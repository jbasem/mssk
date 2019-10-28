resource "aws_elasticache_subnet_group" "redis_db_cache" {
  name       = "${local.ms_name_prefix}-redis-db-cache"
  subnet_ids = data.aws_subnet_ids.all_private.ids
}

resource "aws_elasticache_cluster" "redis_db_cache" {
  engine               = "redis"
  num_cache_nodes      = 1
  cluster_id           = "${local.ms_name_prefix}"
  port                 = "${var.redis_port}"
  node_type            = "${var.redis_instance_class}"
  engine_version       = "${var.redis_engine_version}"
  maintenance_window   = "${var.redis_maintenance_window}"
  security_group_ids   = ["${module.redis_sg.this_security_group_id}"]
  subnet_group_name    = "${aws_elasticache_subnet_group.redis_db_cache.name}"
}