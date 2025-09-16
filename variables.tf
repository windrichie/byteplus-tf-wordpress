# Input Variables for WordPress Terraform Deployment

variable "region" {
  description = "The BytePlus region for deployment"
  type        = string
  default     = "ap-southeast-3"
}

variable "vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where resources can be placed"
  type        = list(string)
}

variable "ecs_instance_type" {
  description = "The instance type for the WordPress server"
  type        = string
  default     = "ecs.g3il.large"
}

variable "db_instance_class" {
  description = "The instance class for the RDS MySQL instance"
  type        = string
  default     = "rds.mysql.1c1g"
}

variable "redis_shard_capacity" {
  description = "The shard capacity for the Cache for Redis instance in MB"
  type        = number
  default     = 256
}

variable "db_name" {
  description = "The name of the MySQL database"
  type        = string
  default     = "wordpress_db"
}

variable "db_username" {
  description = "The username for the MySQL database"
  type        = string
  default     = "wordpress_user"
}

variable "db_password" {
  description = "The password for the MySQL database"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "The password for the Redis instance"
  type        = string
  sensitive   = true
}

variable "wp_admin_password" {
  description = "The initial WordPress admin password"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "The name of the ECS key pair for SSH access"
  type        = string
  default     = "default"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access to ECS instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "cdn_domain" {
  description = "CDN domain name for the WordPress site (e.g., wind.cloudpeek.xyz). If not provided, ALB URL will be used."
  type        = string
  default     = ""
}