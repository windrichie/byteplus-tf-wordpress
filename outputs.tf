# Output values for WordPress deployment

output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer"
  value       = "${byteplus_alb.wordpress_alb.id}.${var.region}.byteplusalb.com"
}

output "wordpress_url" {
  description = "The URL to access the WordPress site"
  value       = var.cdn_domain != "" ? "http://${var.cdn_domain}" : "http://${byteplus_alb.wordpress_alb.id}.${var.region}.byteplusalb.com"
}

output "wordpress_admin_url" {
  description = "The URL to access the WordPress admin portal"
  value       = var.cdn_domain != "" ? "http://${var.cdn_domain}/wp-admin" : "http://${byteplus_alb.wordpress_alb.id}.${var.region}.byteplusalb.com/wp-admin"
}

output "database_endpoint" {
  description = "The RDS MySQL database endpoint"
  value       = byteplus_rds_mysql_instance.wordpress_db.endpoints[0].addresses[0].domain
}

output "redis_endpoint" {
  description = "The Redis cache endpoint"
  value       = "${byteplus_redis_instance.wordpress_cache.id}.redis.ibytepluses.com"
}

output "ecs_instance_id" {
  description = "The ID of the ECS instance"
  value       = byteplus_ecs_instance.wordpress_server.id
}

output "alb_id" {
  description = "The ID of the Application Load Balancer"
  value       = byteplus_alb.wordpress_alb.id
}