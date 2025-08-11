#!/bin/bash

# Startup script for Load Balancer + Existing Nginx Container
# This script will start the load balancer and integrate with your existing nginx

echo "🚀 Starting Load Balancer with Existing Nginx Container..."
echo "=========================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

echo "✅ Docker is running"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed. Please install it first."
    exit 1
fi

echo "✅ docker-compose is available"

# Check if existing nginx container is running
if ! docker ps | grep -q "myapp-nginx"; then
    echo "❌ Container 'myapp-nginx' is not running."
    echo "Please start your existing nginx container first."
    exit 1
fi

echo "✅ Found existing nginx container: myapp-nginx"

# Check if nginx has health check endpoint
echo "🔍 Checking nginx health endpoint..."
if curl -s http://localhost:57755/health | grep -q "healthy"; then
    echo "✅ Nginx health endpoint is working"
else
    echo "⚠️  Nginx health endpoint not found. Adding it now..."
    echo "This will add a /health endpoint to your existing nginx container."
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x scripts/add-health-check-to-nginx.sh
        ./scripts/add-health-check-to-nginx.sh
    else
        echo "❌ Cannot continue without health endpoint. Exiting."
        exit 1
    fi
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p certs config examples

# Set proper permissions for scripts
chmod +x scripts/*.sh

# Start the load balancer (without portainer since you have the extension)
echo "🚀 Starting load balancer services..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
echo "📊 Service Status:"
echo "=================="
docker-compose ps

# Show logs for troubleshooting
echo ""
echo "📋 Recent logs (last 10 lines):"
echo "================================"
docker-compose logs --tail=10

echo ""
echo "🎉 Load Balancer started successfully!"
echo ""
echo "🌐 Access your services:"
echo "   • Your Existing Nginx: http://myapp.local:8080 (load balanced)"
echo "   • Direct Nginx Access: http://localhost:57755"
echo "   • Load Balancer:       http://lb.local:4000"
echo "   • Test Web Apps:       http://web.local:8080 (optional)"
echo ""
echo "📝 Useful commands:"
echo "   • View logs:        docker-compose logs -f"
echo "   • Stop services:    docker-compose down"
echo "   • Restart:          docker-compose restart"
echo "   • Status:           docker-compose ps"
echo ""
echo "🔧 If you haven't configured your hosts file yet, run:"
echo "   • Windows:          .\\scripts\\setup-existing-nginx-hosts.ps1 (as Administrator)"
echo "   • Linux/WSL2:       sudo ./scripts/setup-existing-nginx-hosts.sh"
echo ""
echo "💡 Your existing nginx container is now load balanced!"
echo "   Traffic to http://myapp.local:8080 will go through the load balancer"
echo "   while http://localhost:57755 still works directly."
