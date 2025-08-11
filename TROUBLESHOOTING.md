# 🔧 Troubleshooting Guide for Existing Nginx + Load Balancer

## 🚨 **Common Issues and Solutions**

### 1. **Nginx Container Not Recognized**

**Problem**: The load balancer can't see your existing nginx container.

**Causes**:
- Container is on a different network
- Container name doesn't match configuration
- Health check endpoint missing

**Solutions**:

#### A. **Check Container Status**
```bash
# Verify container is running
docker ps | grep myapp-nginx

# Check container details
docker inspect myapp-nginx

# Check which network it's on
docker network ls
docker network inspect myapp-network
```

#### B. **Add Health Check Endpoint**
```bash
# Run the health check script
./scripts/add-health-check-to-nginx.sh

# Or manually add health endpoint
docker exec myapp-nginx sh -c 'echo "location /health { return 200 \"healthy\"; }" >> /etc/nginx/nginx.conf'
docker exec myapp-nginx nginx -s reload
```

#### C. **Verify Network Configuration**
```bash
# Check if container is on the right network
docker network inspect myapp-network | grep -A 10 "Containers"

# If needed, connect container to load-balancer-network
docker network connect load-balancer-network myapp-nginx
```

### 2. **Portainer Extension Issues**

**Problem**: Portainer extension doesn't work with the load balancer.

**Causes**:
- Docker Desktop extension runs in different context
- Network isolation between extension and containers

**Solutions**:

#### A. **Use Portainer Extension as-is**
- The extension will still work for container management
- Load balancer will discover containers via Docker socket
- No special configuration needed

#### B. **Alternative: Use Portainer Container**
If you prefer a standalone Portainer:
```bash
# Add to docker-compose.yml
portainer:
  image: portainer/portainer-ce:latest
  container_name: portainer
  ports:
    - "9000:9000"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  networks:
    - load-balancer-network
```

### 3. **Health Check Failures**

**Problem**: Load balancer reports containers as unhealthy.

**Causes**:
- Missing `/health` endpoint
- Incorrect health check path
- Container not responding

**Solutions**:

#### A. **Test Health Endpoint Manually**
```bash
# Test from host
curl http://localhost:57755/health

# Test from within container
docker exec myapp-nginx curl http://localhost/health
```

#### B. **Check Nginx Configuration**
```bash
# View nginx config
docker exec myapp-nginx cat /etc/nginx/nginx.conf

# Check nginx logs
docker logs myapp-nginx

# Test nginx config
docker exec myapp-nginx nginx -t
```

#### C. **Add Health Endpoint**
```bash
# Quick health endpoint addition
docker exec myapp-nginx sh -c '
cat >> /etc/nginx/nginx.conf << EOF
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
EOF
'
docker exec myapp-nginx nginx -s reload
```

### 4. **Network Connectivity Issues**

**Problem**: Load balancer can't reach containers.

**Causes**:
- Containers on different networks
- Firewall blocking connections
- Port binding issues

**Solutions**:

#### A. **Check Network Configuration**
```bash
# List all networks
docker network ls

# Inspect network details
docker network inspect myapp-network
docker network inspect load-balancer-network

# Check container IP addresses
docker inspect myapp-nginx | grep IPAddress
```

#### B. **Connect Containers to Same Network**
```bash
# Connect existing container to load balancer network
docker network connect load-balancer-network myapp-nginx

# Or connect load balancer to existing network
docker network connect myapp-network load-balancer
```

#### C. **Verify Port Bindings**
```bash
# Check what ports are bound
docker port myapp-nginx

# Test connectivity from host
telnet localhost 57755
```

### 5. **Configuration Issues**

**Problem**: Load balancer doesn't apply configuration.

**Causes**:
- Wrong config file loaded
- Syntax errors in config
- Config not reloaded

**Solutions**:

#### A. **Check Configuration Loading**
```bash
# Verify config file exists
ls -la config/

# Check config syntax
elixir -c config/existing_nginx_integration.exs

# Restart load balancer to reload config
docker-compose restart load-balancer
```

#### B. **Debug Configuration**
```bash
# View load balancer logs
docker-compose logs load-balancer

# Check if routes are registered
curl http://localhost:4000/api/routes
```

### 6. **Performance Issues**

**Problem**: Load balancer is slow or unresponsive.

**Causes**:
- High health check frequency
- Too many containers
- Resource constraints

**Solutions**:

#### A. **Adjust Health Check Frequency**
```elixir
# In your config file, reduce health check frequency
health_check "/health", interval: 30_000  # Check every 30 seconds
```

#### B. **Monitor Resource Usage**
```bash
# Check container resource usage
docker stats

# Check load balancer logs for errors
docker-compose logs -f load-balancer
```

#### C. **Optimize Configuration**
```elixir
# Use more efficient load balancing strategies
strategy :least_connections  # Instead of round_robin for high traffic
```

## 🚀 **Quick Fix Commands**

### **Reset Everything**
```bash
# Stop all services
docker-compose down

# Remove networks
docker network rm load-balancer-network

# Restart existing nginx
docker restart myapp-nginx

# Start fresh
./start-with-existing-nginx.sh
```

### **Manual Health Check Addition**
```bash
# Quick health endpoint
docker exec myapp-nginx sh -c '
echo "location /health { return 200 \"healthy\"; add_header Content-Type text/plain; }" >> /etc/nginx/nginx.conf
nginx -s reload
'
```

### **Test Connectivity**
```bash
# Test from host
curl http://localhost:57755/health

# Test from load balancer container
docker exec load-balancer curl http://myapp-nginx/health
```

## 📞 **Getting Help**

If you're still having issues:

1. **Check the logs**: `docker-compose logs -f`
2. **Verify container status**: `docker-compose ps`
3. **Test endpoints manually**: `curl http://localhost:PORT/endpoint`
4. **Check network connectivity**: `docker network inspect NETWORK_NAME`
5. **Verify configuration**: Check your config files for syntax errors

## 🔍 **Debug Mode**

Enable debug logging in your load balancer:

```bash
# Set environment variable
export LOAD_BALANCER_LOG_LEVEL=debug

# Restart load balancer
docker-compose restart load-balancer
```

This will give you detailed information about what the load balancer is doing and help identify issues.
