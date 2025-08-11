# Portainer Integration Guide

This guide explains how to set up and use the Elixir Load Balancer with Portainer on Windows, whether running the load balancer in Docker or on bare metal.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop for Windows
- WSL2 enabled (recommended)
- PowerShell (for Windows scripts) or Bash (for WSL2)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd load-balancer
```

### 2. Configure Hosts File

#### Windows (PowerShell as Administrator)
```powershell
.\scripts\setup-windows-hosts.ps1
```

#### WSL2/Linux
```bash
sudo ./scripts/setup-linux-hosts.sh
```

### 3. Start the Stack
```bash
docker-compose up -d
```

### 4. Access Services
- **Portainer**: http://portainer.local:9000
- **Load Balancer Dashboard**: http://lb.local:4000
- **Test Web Apps**: http://web.local:8080
- **Individual Apps**: http://web1.local:8080, http://web2.local:8080

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Windows Host  │    │   WSL2/Docker    │    │   Load Balancer │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │   Browser   │◄────┤ │  Portainer   │ │    │ │   Router    │ │
│ │             │ │    │ │              │ │    │ │             │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                       │
                                │                       │
                                ▼                       ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Web App 1      │    │  Web App 2     │
                       │  (nginx:8081)   │    │  (nginx:8082)  │
                       └──────────────────┘    └─────────────────┘
```

## 🔧 Configuration Details

### Docker Compose Services

#### Load Balancer
- **Port**: 8080 (traffic), 4000 (management)
- **Docker Socket**: Mounted for container discovery
- **Networks**: Connected to `load-balancer-network`

#### Portainer
- **Port**: 9000 (web), 8000 (agent)
- **Docker Socket**: Mounted for container management
- **Data**: Persistent volume for settings

#### Test Applications
- **Web App 1**: nginx on port 8081
- **Web App 2**: nginx on port 8082
- **Health Checks**: `/health` endpoint
- **Custom Content**: `/info` endpoint for identification

### Load Balancer Routes

#### Portainer Management
```elixir
route_domain "portainer.local" do
  container "portainer", "portainer:9000"
  strategy :round_robin
  health_check "/api/status"
end
```

#### Load Balanced Web Apps
```elixir
route_domain "web.local" do
  container "web-app-1", "web-app-1:80"
  container "web-app-2", "web-app-2:80"
  strategy :round_robin
  health_check "/health"
  sticky_sessions cookie: "web_session", ttl: 1800
end
```

#### API with Rate Limiting
```elixir
route_domain "api.local" do
  container "web-app-1", "web-app-1:80"
  container "web-app-2", "web-app-2:80"
  strategy :least_connections
  rate_limit requests: 100, window: 60_000
  circuit_breaker threshold: 5, timeout: 30_000
end
```

## 🧪 Testing the Setup

### 1. Health Checks
```bash
# Test individual app health
curl http://web1.local:8080/health
curl http://web2.local:8080/health

# Test load balancer health
curl http://lb.local:4000/health
```

### 2. Load Balancing
```bash
# Test round-robin distribution
for i in {1..10}; do
  curl -s http://web.local:8080/info
  echo
done
```

### 3. Session Affinity
```bash
# Test sticky sessions
curl -c cookies.txt http://web.local:8080/info
curl -b cookies.txt http://web.local:8080/info
```

### 4. Rate Limiting
```bash
# Test API rate limiting
for i in {1..110}; do
  curl -s http://api.local:8080/info
  echo "Request $i"
done
```

## 🔍 Monitoring and Management

### Portainer Dashboard
- **URL**: http://portainer.local:9000
- **Features**: Container management, logs, resource monitoring
- **Access**: Create admin account on first visit

### Load Balancer Dashboard
- **URL**: http://lb.local:4000
- **Features**: Real-time metrics, route configuration, health status
- **Metrics**: Response times, error rates, connection counts

### Container Health Monitoring
```bash
# View container status
docker ps

# Check container logs
docker logs load-balancer
docker logs portainer
docker logs web-app-1
docker logs web-app-2

# Monitor resource usage
docker stats
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Hosts File Not Working
```bash
# Windows: Run PowerShell as Administrator
# WSL2: Use sudo
# Verify entries exist
cat /etc/hosts | grep local
```

#### 2. Port Conflicts
```bash
# Check what's using the ports
netstat -ano | findstr :8080
netstat -ano | findstr :4000
netstat -ano | findstr :9000
```

#### 3. Docker Socket Access
```bash
# Verify Docker is running
docker version

# Check socket permissions
ls -la /var/run/docker.sock
```

#### 4. Container Communication
```bash
# Test network connectivity
docker exec load-balancer ping web-app-1
docker exec load-balancer ping web-app-2
docker exec load-balancer ping portainer
```

### Debug Commands

#### Load Balancer Debug
```bash
# View logs
docker logs -f load-balancer

# Interactive shell
docker exec -it load-balancer sh

# Check configuration
docker exec load-balancer cat /app/config/portainer_integration.exs
```

#### Network Debug
```bash
# Inspect network
docker network inspect load-balancer-load-balancer-network

# Test DNS resolution
docker exec load-balancer nslookup web-app-1
docker exec load-balancer nslookup portainer
```

## 🔄 Advanced Configuration

### Custom Domain Names
Edit `config/portainer_integration.exs` to add your own domains:

```elixir
route_domain "myapp.local" do
  container "myapp", "myapp:3000"
  strategy :least_connections
  health_check "/health"
  ssl_config cert: "/certs/myapp.pem", key: "/certs/myapp.key"
end
```

### SSL/TLS Configuration
1. Place certificates in `./certs/` directory
2. Update configuration with SSL settings
3. Restart the load balancer

### Environment Variables
```bash
# Customize load balancer behavior
export LOAD_BALANCER_PORT=8080
export LOAD_BALANCER_WEB_PORT=4000
export LOAD_BALANCER_LOG_LEVEL=debug
export DOCKER_HOST=unix:///var/run/docker.sock
```

## 📊 Performance Tuning

### Load Balancer Settings
- **Health Check Interval**: 30 seconds (default)
- **Connection Timeout**: 5 seconds
- **Rate Limiting**: Configurable per domain
- **Circuit Breaker**: Automatic failover

### Container Resources
```yaml
# Add to docker-compose.yml
services:
  load-balancer:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### Monitoring and Alerting
- **Metrics Export**: Prometheus format
- **Health Checks**: Automatic container monitoring
- **Log Aggregation**: Centralized logging
- **Performance Alerts**: Configurable thresholds

## 🚀 Production Deployment

### Security Considerations
- **Docker Socket**: Read-only access
- **Network Isolation**: Separate networks for different environments
- **SSL/TLS**: Proper certificate management
- **Authentication**: Secure access to management interfaces

### Scaling
- **Horizontal Scaling**: Multiple load balancer instances
- **Auto-scaling**: Based on CPU/memory usage
- **Load Distribution**: Multiple Portainer instances
- **Backup and Recovery**: Regular backups of configuration

### High Availability
- **Failover**: Automatic container failover
- **Health Monitoring**: Continuous health checks
- **Circuit Breakers**: Fault tolerance
- **Backup Routes**: Secondary domain routing

## 📚 Additional Resources

### Documentation
- [Elixir Load Balancer README](README.md)
- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

### Community
- [GitHub Issues](https://github.com/your-repo/issues)
- [Elixir Forum](https://elixirforum.com/)
- [Portainer Community](https://community.portainer.io/)

### Support
For issues and questions:
1. Check the troubleshooting section
2. Review logs and configuration
3. Create a GitHub issue
4. Join community discussions

---

**Happy Load Balancing! 🎉**
