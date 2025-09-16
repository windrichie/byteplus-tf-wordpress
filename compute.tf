# Compute Resources for WordPress Deployment

# Data source for ECS key pairs
data "byteplus_ecs_key_pairs" "default_key_pair" {
  key_pair_name = var.key_pair_name
}

# Security Group for ECS instances
resource "byteplus_security_group" "ecs_sg" {
  vpc_id              = var.vpc_id
  security_group_name = "${local.project_name}-ecs-sg"
  description         = "Security group for WordPress ECS instances"
}

# Security group rule: Allow HTTP from VPC CIDR (for ALB communication)
resource "byteplus_security_group_rule" "ecs_sg_ingress_http" {
  security_group_id = byteplus_security_group.ecs_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = "80"
  port_end          = "80"
  cidr_ip           = data.byteplus_vpcs.main.vpcs[0].cidr_block
  description       = "Allow HTTP from VPC CIDR"
}

# Security group rule: Allow SSH access
resource "byteplus_security_group_rule" "ecs_sg_ingress_ssh" {
  security_group_id = byteplus_security_group.ecs_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = "22"
  port_end          = "22"
  cidr_ip           = var.allowed_ssh_cidr
  description       = "Allow SSH access"
}

# Security group rule: Allow all outbound traffic
resource "byteplus_security_group_rule" "ecs_sg_egress" {
  security_group_id = byteplus_security_group.ecs_sg.id
  direction         = "egress"
  protocol          = "all"
  port_start        = "-1"
  port_end          = "-1"
  cidr_ip           = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

# Application Load Balancer
resource "byteplus_alb" "wordpress_alb" {
  address_ip_version = "IPv4"
  type              = "public"
  load_balancer_name = "${local.project_name}-alb"
  subnet_ids        = var.subnet_ids
  
  eip_billing_config {
    isp              = "BGP"
    eip_billing_type = "PostPaidByTraffic"
    bandwidth        = 200
  }
}

# ALB Server Group
resource "byteplus_alb_server_group" "wordpress_server_group" {
  vpc_id            = var.vpc_id
  server_group_name = "${local.project_name}-server-group"
  description       = "Server group for WordPress instances"
  
  health_check {
    enabled     = "on"
    domain      = ""
    uri         = "/"
    method      = "GET"
    http_code   = "http_2xx"
    interval    = 10
    timeout     = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# ALB Listener
resource "byteplus_alb_listener" "wordpress_listener" {
  load_balancer_id = byteplus_alb.wordpress_alb.id
  listener_name    = "${local.project_name}-http-listener"
  protocol         = "HTTP"
  port             = 80
  enabled          = "on"
  server_group_id  = byteplus_alb_server_group.wordpress_server_group.id
}

# ALB Redirect Rule - /multicloud to /byteplus-dr-multicloud
resource "byteplus_alb_rule" "multicloud_redirect" {
  listener_id = byteplus_alb_listener.wordpress_listener.id
  domain      = ""
  url         = "/multicloud"
  
  rule_action = "Redirect"
  redirect_config {
    redirect_uri      = "/byteplus-dr-multicloud"
    redirect_protocol = "HTTP"
  }
}

# ECS Instance for WordPress
resource "byteplus_ecs_instance" "wordpress_server" {
  instance_name        = "${local.project_name}-server"
  description          = "WordPress server instance"
  host_name            = "${local.project_name}-server"
  image_id             = [for image in data.byteplus_images.ubuntu22.images : image.image_id if image.image_name == "Ubuntu 22.04 64 bit"][0]
  instance_type        = var.ecs_instance_type
  key_pair_name        = data.byteplus_ecs_key_pairs.default_key_pair.key_pairs[0].key_pair_name
  security_group_ids   = [byteplus_security_group.ecs_sg.id]
  subnet_id            = var.subnet_ids[0]
  instance_charge_type = "PostPaid"
  system_volume_type   = "ESSD_PL0"
  system_volume_size   = 40
  
  data_volumes {
    volume_type          = "ESSD_PL0"
    size                 = 50
    delete_with_instance = true
  }

  # User data script with template variable replacements
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    SITE_URL     = var.cdn_domain != "" ? "http://${var.cdn_domain}" : "http://${byteplus_alb.wordpress_alb.id}.${var.region}.byteplusalb.com"
    DB_HOST      = byteplus_rds_mysql_instance.wordpress_db.endpoints[0].addresses[0].domain
    DB_NAME      = var.db_name
    DB_USER      = var.db_username
    DB_PASS      = var.db_password
    REDIS_HOST   = "${byteplus_redis_instance.wordpress_cache.id}.redis.ibytepluses.com"
    REDIS_PORT   = "6379"
    REDIS_PASS   = var.redis_password
    WP_ADMIN_PASS = var.wp_admin_password
  }))

  lifecycle {
    create_before_destroy = true
  }
}

# Attach ECS instance to ALB server group
resource "byteplus_alb_server_group_server" "wordpress_server_attachment" {
  server_group_id = byteplus_alb_server_group.wordpress_server_group.id
  instance_id     = byteplus_ecs_instance.wordpress_server.id
  type            = "ecs"
  weight          = 100
  port            = 80
  ip              = byteplus_ecs_instance.wordpress_server.primary_ip_address
  description     = "WordPress server attachment"
}