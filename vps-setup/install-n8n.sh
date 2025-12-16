#!/bin/bash
# VPS Setup Script for soar-brain SOAR Controller
# Run as root or with sudo on Hostinger VPS (Ubuntu/Debian assumed)

set -e

echo "Starting VPS setup for soar-brain SOAR controller..."

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js (required for n8n)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install n8n globally
echo "Installing n8n..."
npm install -g n8n

# Create n8n user
echo "Creating n8n user..."
useradd -m -s /bin/bash n8n || echo "User n8n already exists"

# Create directories
echo "Setting up directories..."
mkdir -p /home/n8n/.n8n
chown -R n8n:n8n /home/n8n/.n8n

# Create systemd service for n8n
echo "Creating systemd service..."
cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
Type=simple
User=n8n
WorkingDirectory=/home/n8n
ExecStart=/usr/local/bin/n8n
Restart=always
RestartSec=10
Environment=N8N_PORT=5678
Environment=N8N_PROTOCOL=https
Environment=N8N_SSL_CERT=/path/to/ssl/cert.pem
Environment=N8N_SSL_KEY=/path/to/ssl/private.key

[Install]
WantedBy=multi-user.target
EOF

# Install nginx for reverse proxy and rate limiting
echo "Installing nginx..."
apt install -y nginx

# Configure nginx for n8n with rate limiting
echo "Configuring nginx reverse proxy..."
cat > /etc/nginx/sites-available/n8n <<EOF
upstream n8n {
    server 127.0.0.1:5678;
}

server {
    listen 80;
    server_name your-vps-domain.com;  # Replace with your domain

    # Rate limiting: 10 requests per minute per IP
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/m;
    limit_req zone=api burst=5 nodelay;

    location / {
        proxy_pass http://n8n;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Webhook endpoint with stricter limits
    location /webhook/ {
        limit_req zone=api burst=2 nodelay;
        proxy_pass http://n8n;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Install fail2ban for additional security
echo "Installing fail2ban..."
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Firewall setup (ufw)
echo "Configuring firewall..."
apt install -y ufw
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# SSL certificate (Let's Encrypt)
echo "Installing certbot for SSL..."
apt install -y certbot python3-certbot-nginx
# Run: certbot --nginx -d your-vps-domain.com

# Start n8n
echo "Starting n8n service..."
systemctl daemon-reload
systemctl enable n8n
systemctl start n8n

echo "VPS setup complete!"
echo "Next steps:"
echo "1. Obtain SSL certificate: certbot --nginx -d your-domain.com"
echo "2. Access n8n at https://your-domain.com"
echo "3. Import workflows from n8n-workflows/ directory"
echo "4. Configure authentication tokens and database if needed"