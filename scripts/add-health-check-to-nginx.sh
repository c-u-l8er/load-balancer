#!/bin/bash

# Script to add health check endpoint to existing nginx container
# This will create a new nginx config with health check and copy it to your container

echo "🔧 Adding health check endpoint to existing nginx container..."

# Check if container is running
if ! docker ps | grep -q "myapp-nginx"; then
    echo "❌ Container 'myapp-nginx' is not running. Please start it first."
    exit 1
fi

echo "✅ Found running container: myapp-nginx"

# Create a health check nginx config
cat > /tmp/nginx-with-health.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }

        # Status endpoint for load balancer
        location /status {
            access_log off;
            return 200 "nginx is running\n";
            add_header Content-Type text/plain;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF

echo "📝 Created nginx config with health check endpoint"

# Copy the config to the container
echo "📤 Copying config to container..."
docker cp /tmp/nginx-with-health.conf myapp-nginx:/etc/nginx/nginx.conf

# Reload nginx configuration
echo "🔄 Reloading nginx configuration..."
docker exec myapp-nginx nginx -s reload

# Test the health endpoint
echo "🧪 Testing health endpoint..."
sleep 2
if curl -s http://localhost:57755/health | grep -q "healthy"; then
    echo "✅ Health check endpoint working at http://localhost:57755/health"
else
    echo "❌ Health check endpoint not working. Checking nginx logs..."
    docker logs myapp-nginx --tail=10
fi

# Clean up
rm -f /tmp/nginx-with-health.conf

echo ""
echo "🎉 Health check endpoint added successfully!"
echo "You can now use your existing nginx container with the load balancer."
echo ""
echo "Test endpoints:"
echo "  - Health: http://localhost:57755/health"
echo "  - Status: http://localhost:57755/status"
echo "  - Main:  http://localhost:57755/"
