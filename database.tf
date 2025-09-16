# Database Resources for WordPress Deployment

# Data source to get VPC information for CIDR block
data "byteplus_vpcs" "main" {
  ids = [var.vpc_id]
}

# RDS MySQL Instance
resource "byteplus_rds_mysql_instance" "wordpress_db" {
  db_engine_version      = "MySQL_8_0"
  node_spec             = var.db_instance_class
  primary_zone_id       = "${var.region}a"
  secondary_zone_id     = "${var.region}b"
  instance_name         = "${local.project_name}-mysql"
  storage_space         = 50
  subnet_id             = var.subnet_ids[0]
  lower_case_table_names = "1"
  
  charge_info {
    charge_type = "PostPaid"
  }
}

# Create MySQL Database
resource "byteplus_rds_mysql_database" "wordpress" {
  instance_id = byteplus_rds_mysql_instance.wordpress_db.id
  db_name     = var.db_name
}

# Create MySQL User Account
resource "byteplus_rds_mysql_account" "wordpress_user" {
  instance_id      = byteplus_rds_mysql_instance.wordpress_db.id
  account_name     = var.db_username
  account_password = var.db_password
  account_type     = "Super"
}

# RDS MySQL Allowlist
resource "byteplus_rds_mysql_allowlist" "wordpress_allowlist" {
  allow_list_name = "${local.project_name}-mysql-allowlist"
  allow_list_desc = "Allowlist for WordPress MySQL database"
  allow_list_type = "IPv4"
  allow_list      = [data.byteplus_vpcs.main.vpcs[0].cidr_block]
}

# Associate Allowlist with MySQL Instance
resource "byteplus_rds_mysql_allowlist_associate" "wordpress_allowlist_assoc" {
  instance_id    = byteplus_rds_mysql_instance.wordpress_db.id
  allow_list_id  = byteplus_rds_mysql_allowlist.wordpress_allowlist.id
}

# Cache for Redis Instance
resource "byteplus_redis_instance" "wordpress_cache" {
  multi_az            = "disabled"
  instance_name       = "${local.project_name}-redis"
  sharded_cluster     = 0
  password            = var.redis_password
  node_number         = 1
  shard_capacity      = var.redis_shard_capacity
  engine_version      = "7.0"
  subnet_id           = var.subnet_ids[0]
  deletion_protection = "disabled"
  vpc_auth_mode       = "close"
  charge_type         = "PostPaid"
  
  # Enable flushdb command by removing it from disabled-commands
  param_values {
    name = "disabled-commands"
    value = "flushall,keys"
  }
  
  configure_nodes {
    az = "${var.region}a"
  }

  # lifecycle {
  #   ignore_changes = [param_values]
  # }
}

# Redis Allowlist
resource "byteplus_redis_allow_list" "wordpress_redis_allowlist" {
  allow_list_name = "${local.project_name}-redis-allowlist"
  allow_list_desc = "Allowlist for WordPress Redis cache"
  allow_list      = [data.byteplus_vpcs.main.vpcs[0].cidr_block]
}

# Associate Redis Allowlist with Redis Instance
resource "byteplus_redis_allow_list_associate" "wordpress_redis_allowlist_assoc" {
  instance_id   = byteplus_redis_instance.wordpress_cache.id
  allow_list_id = byteplus_redis_allow_list.wordpress_redis_allowlist.id
}