# Load Balancer in Elixir

A powerful, macro-based load balancer built in Elixir for handling traffic from domain names to Docker containers. This system provides enterprise-grade load balancing with advanced features like health checks, SSL termination, rate limiting, and automatic scaling.

## Features

### 🚀 Core Load Balancing
- **Multiple Strategies**: Round-robin, least connections, IP hash, and weighted round-robin
- **Domain-based Routing**: Route traffic based on domain names to different container pools
- **Health Checks**: Automatic health monitoring of containers with configurable endpoints
- **Connection Tracking**: Real-time connection counting and load distribution

### 🛡️ Advanced Features
- **SSL/TLS Support**: SSL termination and certificate management per domain
- **Rate Limiting**: Configurable rate limiting per domain with sliding window
- **Sticky Sessions**: Session affinity for consistent user experience
- **Circuit Breaker**: Fault tolerance with automatic failover
- **Auto-scaling**: Automatic container scaling based on metrics
- **Failover**: Backup domain routing when primary containers are unavailable

### 📊 Monitoring & Management
- **Real-time Metrics**: Response time, error rates, throughput, and connection counts
- **Web Dashboard**: Phoenix LiveView-based management interface
- **REST API**: Programmatic configuration and monitoring
- **Health Monitoring**: Container status and performance tracking

## Architecture

The load balancer is built using Elixir's actor model and supervision trees:

```
LoadBalancer.Application
├── LoadBalancer.Router          # Domain routing and request handling
├── LoadBalancer.Strategy        # Load balancing algorithms
├── LoadBalancer.ContainerManager # Docker container management
├── LoadBalancer.HealthChecker   # Health monitoring
├── LoadBalancer.SSL             # SSL/TLS configuration
├── LoadBalancer.RateLimiter     # Rate limiting
├── LoadBalancer.SessionManager  # Sticky sessions
├── LoadBalancer.CircuitBreaker  # Fault tolerance
├── LoadBalancer.Monitor         # Metrics collection
├── LoadBalancer.AutoScaler      # Automatic scaling
├── LoadBalancer.Failover        # Failover management
└── LoadBalancerWeb.Endpoint     # Web management interface
```

## Installation

### Prerequisites
- Elixir 1.14+
- Erlang/OTP 24+
- Docker
- Mix

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd load-balancer
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Configure the load balancer**
   Edit `lib/load_balancer/config.ex` to define your domains and containers.

4. **Start the application**
   ```bash
   mix run --no-halt
   ```

## Docker Deployment

### Prerequisites
- Docker
- Docker Compose

### Quick Start

1. **Build and start the services**
   ```bash
   docker-compose up -d
   ```

2. **Access the management interface**
   - Web Dashboard: http://localhost:4001
   - Load Balancer: http://localhost:8080

3. **Domain data persistence**
   - Domain configurations are stored in `./data/domains.json`
   - This directory is mounted as a volume in the container
   - Data persists across container restarts

### Configuration

The Docker setup includes:
- **Load Balancer**: Main application on port 8080
- **Web Management**: Phoenix interface on port 4001
- **Example Apps**: Two nginx containers for testing
- **Data Persistence**: Mounted `./data` directory for domain storage
- **SSL Support**: Mounted `./certs` directory for certificates
- **Docker Socket**: Access to manage containers

## Configuration

The load balancer uses a powerful macro system for configuration. Here's how to define domain routes:

```elixir
import LoadBalancer.Macros

# Define a domain route
route_domain "example.com" do
  container "web1", "web1:8080"
  container "web2", "web2:8080"
  container "web3", "web3:8080"
  
  strategy :round_robin
  health_check "/health"
  
  ssl_config cert: "/certs/example.com.pem", key: "/certs/example.com.key"
  rate_limit requests: 1000, window: 60_000
  sticky_sessions cookie: "session_id", ttl: 3600
  circuit_breaker threshold: 5, timeout: 60_000
  monitor metrics: [:response_time, :error_rate, :throughput]
  auto_scale min: 2, max: 10, cpu_threshold: 80
  failover backup_domain: "backup.example.com", health_check: "/health"
end
```

### Configuration Options

| Option | Description | Example |
|--------|-------------|---------|
| `container` | Define a container endpoint | `container "app1", "app1:8080"` |
| `strategy` | Load balancing strategy | `strategy :round_robin` |
| `health_check` | Health check endpoint | `health_check "/health"` |
| `ssl_config` | SSL certificate configuration | `ssl_config cert: "cert.pem", key: "key.pem"` |
| `rate_limit` | Rate limiting rules | `rate_limit requests: 100, window: 60_000` |
| `sticky_sessions` | Session affinity | `sticky_sessions cookie: "session_id", ttl: 3600` |
| `circuit_breaker` | Fault tolerance | `circuit_breaker threshold: 5, timeout: 60_000` |
| `monitor` | Metrics collection | `monitor metrics: [:response_time, :error_rate]` |
| `auto_scale` | Automatic scaling | `auto_scale min: 2, max: 10, cpu_threshold: 80` |
| `failover` | Backup routing | `failover backup_domain: "backup.com"` |

## Load Balancing Strategies

### Round Robin
Distributes requests evenly across all containers in sequence.

```elixir
strategy :round_robin
```

### Least Connections
Routes requests to the container with the fewest active connections.

```elixir
strategy :least_connections
```

### IP Hash
Consistently routes requests from the same IP to the same container.

```elixir
strategy :ip_hash
```

### Weighted Round Robin
Distributes requests based on container weights (future enhancement).

```elixir
strategy :weighted_round_robin
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Metrics
```bash
GET /metrics
```

### Routes Management
```bash
GET    /api/routes          # Get all routes
POST   /api/routes          # Create a new route
PUT    /api/routes/:domain  # Update a route
DELETE /api/routes/:domain  # Delete a route
```

### Container Management
```bash
GET    /api/containers          # Get all containers
POST   /api/containers          # Create a new container
PUT    /api/containers/:name    # Update a container
DELETE /api/containers/:name    # Delete a container
```

## Web Dashboard

Access the web management interface at `http://localhost:4000`:

- **Dashboard**: Overview of all domains and containers
- **Domains**: Manage domain configurations
- **Containers**: Monitor container health and status
- **Metrics**: Real-time performance metrics

## Docker Integration

The load balancer automatically:

- Discovers running Docker containers
- Monitors container health
- Routes traffic to healthy containers
- Manages container lifecycle

### Container Health Checks

Containers should expose a health check endpoint (default: `/health`) that returns:
- `200 OK` for healthy containers
- Any other status for unhealthy containers

## Production Deployment

### Environment Variables
```bash
export LOAD_BALANCER_PORT=8080
export LOAD_BALANCER_WEB_PORT=4000
export LOAD_BALANCER_SSL_CERTS_PATH=/etc/ssl/certs
export LOAD_BALANCER_LOG_LEVEL=info
```

### Docker Compose
```yaml
version: '3.8'
services:
  load-balancer:
    build: .
    ports:
      - "8080:8080"
      - "4000:4000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./certs:/etc/ssl/certs
    environment:
      - LOAD_BALANCER_PORT=8080
      - LOAD_BALANCER_WEB_PORT=4000
```

## Monitoring and Alerting

### Metrics Collected
- Request count and response times
- Error rates and status codes
- Container health status
- Connection counts per container
- Load balancing strategy performance

### Integration
- Prometheus metrics export
- Grafana dashboards
- AlertManager integration
- Custom webhook notifications

## Development

### Running Tests
```bash
mix test
```

### Code Quality
```bash
mix format
mix credo
mix dialyzer
```

### Interactive Development
```bash
iex -S mix
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the examples in `lib/load_balancer/config.ex`

## Roadmap

- [ ] Weighted round-robin strategy
- [ ] Advanced SSL/TLS features
- [ ] WebSocket support
- [ ] gRPC load balancing
- [ ] Kubernetes integration
- [ ] Service mesh integration
- [ ] Advanced metrics and alerting
- [ ] Multi-region support
- [ ] Blue-green deployment support
