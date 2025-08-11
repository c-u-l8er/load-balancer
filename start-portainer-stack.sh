#!/bin/bash

# Startup script for Portainer + Load Balancer stack
# This script will start all services and provide status information

echo "🚀 Starting Portainer + Load Balancer Stack..."
echo "================================================"

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

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p certs config examples

# Set proper permissions for scripts
chmod +x scripts/*.sh

# Start the stack
echo "🚀 Starting services..."
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
echo "🎉 Stack started successfully!"
echo ""
echo "🌐 Access your services:"
echo "   • Portainer:        http://portainer.local:9000"
echo "   • Load Balancer:    http://lb.local:4000"
echo "   • Web Apps:         http://web.local:8080"
echo "   • Individual Apps:  http://web1.local:8080, http://web2.local:8080"
echo "   • API:              http://api.local:8080"
echo ""
echo "📝 Useful commands:"
echo "   • View logs:        docker-compose logs -f"
echo "   • Stop services:    docker-compose down"
echo "   • Restart:          docker-compose restart"
echo "   • Status:           docker-compose ps"
echo ""
echo "🔧 If you haven't configured your hosts file yet, run:"
echo "   • Windows:          .\\scripts\\setup-windows-hosts.ps1 (as Administrator)"
echo "   • Linux/WSL2:       sudo ./scripts/setup-linux-hosts.sh"
