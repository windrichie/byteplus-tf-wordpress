# WordPress on BytePlus with Terraform

A complete Terraform configuration for deploying a production-ready WordPress site on BytePlus cloud infrastructure with Redis caching, RDS MySQL database, and Application Load Balancer.

## 🏗️ Architecture

- **ALB (Application Load Balancer)** - Public-facing load balancer
- **ECS Instance** - Ubuntu 22.04 server running WordPress with Nginx and PHP 8.1
- **RDS MySQL** - Managed database for WordPress
- **Redis Cache** - Object caching for improved performance
- **Security Groups** - Network security for all components
- **CDN Support** - Optional CDN domain configuration

## 📋 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- BytePlus account with appropriate permissions
- BytePlus credentials (Access Key & Secret Key)
- Existing VPC and subnets

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd bp-wordpress-tf
```

### 2. Configure Credentials

```bash
# Copy and edit environment variables
cp envvars-template.sh envvars.sh
# Edit envvars.sh with your BytePlus credentials
source envvars.sh
```

### 3. Configure Variables

```bash
# Copy and edit Terraform variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

**Key values to update in `terraform.tfvars`:**
- `vpc_id` and `subnet_ids` - Your existing network resources
- `db_password`, `redis_password`, `wp_admin_password` - Strong passwords
- `key_pair_name` - Your ECS key pair name
- `cdn_domain` - Your CDN domain (optional)

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## 📁 File Structure

```
├── main.tf                    # Main configuration and data sources
├── variables.tf               # Input variables
├── database.tf                # RDS MySQL and Redis resources
├── compute.tf                 # ALB, ECS, and security groups
├── outputs.tf                 # Output values
├── userdata.sh                # WordPress installation script
├── providers.tf               # Provider configuration
├── envvars-template.sh        # Environment variables template
├── terraform.tfvars.example   # Terraform variables template
├── .gitignore                 # Git ignore rules
└── README.md                  # This file

# Files you create (not in repo):
├── envvars.sh                 # Your actual credentials (git ignored)
└── terraform.tfvars           # Your actual variables (git ignored)
```

## ⚙️ Configuration Options

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `vpc_id` | Existing VPC ID | `"vpc-xxxxx"` |
| `subnet_ids` | List of subnet IDs | `["subnet-a", "subnet-b"]` |
| `db_password` | MySQL database password | `"SecurePass123!"` |
| `redis_password` | Redis instance password | `"RedisPass123!"` |
| `wp_admin_password` | WordPress admin password | `"WPAdmin123!"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | BytePlus region | `"ap-southeast-3"` |
| `ecs_instance_type` | ECS instance type | `"ecs.g1ie.large"` |
| `db_instance_class` | RDS instance class | `"rds.mysql.1c1g"` |
| `redis_shard_capacity` | Redis capacity in MB | `256` |
| `cdn_domain` | CDN domain name | `""` (uses ALB) |

## 🌐 CDN Configuration

To use a CDN in front of your WordPress site:

1. Set `cdn_domain` in `terraform.tfvars`:
   ```hcl
   cdn_domain = "your-cdn-domain.com"
   ```

2. Configure your CDN to point to the ALB endpoint (available in outputs)

3. WordPress will automatically use HTTPS URLs for the CDN domain

## 📊 Outputs

After deployment, you'll get:

- `wordpress_url` - Main WordPress site URL
- `wordpress_admin_url` - WordPress admin panel URL
- `alb_dns_name` - ALB endpoint for CDN configuration
- `ecs_instance_public_ip` - Server IP for SSH access

## 🔧 Post-Deployment

### Access WordPress Admin

1. Get the admin URL from outputs: `terraform output wordpress_admin_url`
2. Login with username: `admin` and your configured password
3. **Important**: After migration, use your original site's admin credentials

### Connect to Server

**Recommended: Use BytePlus Console (More Secure)**

1. Go to BytePlus Console → ECS → Instances
2. Find your WordPress instance
3. Click "Connect" → "ECS Terminal"
4. Use the web-based terminal for secure access

### Check Deployment Status

Monitor the WordPress installation progress:

```bash
# Check userdata script execution logs
tail -f /root/userdata-output.log

# Check if all services are running
systemctl status nginx php8.1-fpm
```


## 🚨 Important Notes

### Migration Support

This setup is optimized for WordPress migration using Migrate Guru:

1. Deploy the infrastructure
2. Access WordPress admin and install Migrate Guru
3. Perform migration from your source site
4. Clear cache: `wp cache flush && wp redis flush`

### Password Requirements

Use strong passwords for:
- Database (`db_password`)
- Redis (`redis_password`) 
- WordPress admin (`wp_admin_password`)


## 🛠️ Troubleshooting

### Common Issues

**WordPress shows old content after migration:**
```bash
sudo -u www-data wp cache flush
sudo -u www-data wp redis flush
```

**Can't login after migration:**
```bash
# Check existing users
sudo -u www-data wp user list
# Reset password for admin user
sudo -u www-data wp user update admin --user_pass='NewPassword123'
```

**Redis connection issues:**
```bash
# Check Redis status
sudo -u www-data wp redis status
# Verify Redis configuration
sudo -u www-data wp config get WP_REDIS_HOST
```

**⚠️ Security Notice**: Always review and customize the configuration for your specific security requirements before deploying to production.