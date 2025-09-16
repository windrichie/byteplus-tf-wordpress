#!/bin/bash
#
# User Data Script for Automated WordPress Installation on Ubuntu 22.04
# All output from this script will be logged to /root/userdata-output.log
#
exec > /root/userdata-output.log 2>&1

# --- 0. Template Variables (Replaced by Terraform during deployment) ---
SITE_URL="${SITE_URL}"
DB_HOST="${DB_HOST}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
REDIS_HOST="${REDIS_HOST}"
REDIS_PORT="${REDIS_PORT}"
REDIS_PASS="${REDIS_PASS}"
WP_ADMIN_PASS="${WP_ADMIN_PASS}"

# --- 1. System Preparation ---
echo "--- Updating system packages ---"
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

echo "--- Installing required packages (Nginx, PHP, MySQL Client, Redis Client, Unzip) ---"
apt install -y nginx php8.1-fpm php8.1-mysql php8.1-xml php8.1-mbstring php8.1-curl php8.1-gd php8.1-zip php8.1-intl php-redis mysql-client unzip

# --- 2. Nginx Configuration ---
echo "--- Configuring Nginx for WordPress ---"
# Create the web root directory
mkdir -p /var/www/html

# Create the Nginx site configuration
cat <<EOF > /etc/nginx/sites-available/wordpress
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php index.html index.htm;
    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Disable the default site and enable the new WordPress site
unlink /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

# Test and reload Nginx
nginx -t
systemctl reload nginx

# --- 3. WP-CLI Installation ---
echo "--- Installing WP-CLI ---"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# --- 4. WordPress Installation & Configuration ---
echo "--- Setting up WordPress directory ---"
# Set correct ownership for the web server user
chown -R www-data:www-data /var/www/html
cd /var/www/html

echo "--- Downloading and configuring WordPress ---"
# Download WordPress core files
sudo -u www-data wp core download

# Create wp-config.php with database details
sudo -u www-data wp config create --dbname="${DB_NAME}" --dbuser="${DB_USER}" --dbpass="${DB_PASS}" --dbhost="${DB_HOST}"

# Add Redis configuration to wp-config.php, including the password
echo "--- Configuring Redis with authentication ---"
sudo -u www-data wp config set WP_REDIS_HOST "${REDIS_HOST}"
sudo -u www-data wp config set WP_REDIS_PORT "${REDIS_PORT}"
# Set Redis password as a string value (without --raw to avoid PHP parsing issues)
sudo -u www-data wp config set WP_REDIS_PASSWORD "${REDIS_PASS}"

# Install WordPress, creating a temporary admin user with your defined password
echo "--- Installing WordPress core with user-defined admin password ---"
# Use single quotes around parameter values to prevent shell interpretation of special characters
sudo -u www-data wp core install --url='${SITE_URL}' --title='Automated WP Site' --admin_user='admin' --admin_password='${WP_ADMIN_PASS}' --admin_email='admin@example.com'

# --- 5. Install Required Plugins ---
echo "--- Installing Migrate Guru and Redis Object Cache plugins ---"
sudo -u www-data wp plugin install migrate-guru --activate
sudo -u www-data wp plugin install redis-cache --activate
# Enable Redis Object Cache
echo "--- Enabling Redis Object Cache ---"
sudo -u www-data wp redis enable

# --- 6. Finalization ---
echo "--- Restarting services and finalizing setup ---"
systemctl restart php8.1-fpm
systemctl restart nginx

echo "--- WordPress setup complete. Awaiting migration. ---"
echo "--- All script output has been logged to /root/userdata-output.log ---"
