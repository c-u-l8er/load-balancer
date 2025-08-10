#!/usr/bin/env elixir

# Simple Load Balancer Example
# This script demonstrates how to use the load balancer macros

# Import the load balancer macros
import LoadBalancer.Macros

# Example 1: Simple web application load balancing
route_domain "myapp.com" do
  container "web1", "web1:8080"
  container "web2", "web2:8080"
  strategy :round_robin
  health_check "/health"
end

# Example 2: API service with advanced features
route_domain "api.myapp.com" do
  container "api1", "api1:3000"
  container "api2", "api2:3000"
  container "api3", "api3:3000"

  strategy :least_connections
  health_check "/ping"
  rate_limit requests: 1000, window: 60_000
  circuit_breaker threshold: 5, timeout: 30_000
  monitor metrics: [:response_time, :error_rate]
end

# Example 3: Static content with SSL
route_domain "static.myapp.com" do
  container "cdn1", "cdn1:80"
  container "cdn2", "cdn2:80"

  strategy :ip_hash
  health_check "/health"
  ssl_config cert: "/certs/static.myapp.com.pem", key: "/certs/static.myapp.com.key"
  rate_limit requests: 2000, window: 60_000
end

# Example 4: Admin panel with strict limits
route_domain "admin.myapp.com" do
  container "admin1", "admin1:9000"

  strategy :round_robin
  health_check "/admin/health"
  ssl_config cert: "/certs/admin.myapp.com.pem", key: "/certs/admin.myapp.com.key"
  rate_limit requests: 100, window: 60_000
  sticky_sessions cookie: "admin_session", ttl: 1800
  monitor metrics: [:response_time, :error_rate, :access_logs]
end

# Example 5: Microservice with auto-scaling
route_domain "service.myapp.com" do
  container "service1", "service1:4000"
  container "service2", "service2:4000"

  strategy :round_robin
  health_check "/health"
  circuit_breaker threshold: 10, timeout: 120_000
  monitor metrics: [:response_time, :error_rate, :throughput, :queue_depth]
  auto_scale min: 2, max: 10, cpu_threshold: 70
end

# Example 6: Legacy system with failover
route_domain "legacy.myapp.com" do
  container "legacy1", "legacy1:8080"

  strategy :round_robin
  health_check "/status"
  failover backup_domain: "modern.myapp.com", health_check: "/health"
end

# Example 7: Development environment
route_domain "dev.myapp.com" do
  container "dev1", "dev1:5000"
  container "dev2", "dev2:5000"

  strategy :round_robin
  health_check "/dev/health"
  monitor metrics: [:response_time, :error_rate]
end

# Example 8: Staging environment
route_domain "staging.myapp.com" do
  container "staging1", "staging1:6000"
  container "staging2", "staging2:6000"

  strategy :least_connections
  health_check "/staging/health"
  rate_limit requests: 200, window: 60_000
  monitor metrics: [:response_time, :error_rate, :throughput]
end

# Example 9: Monitoring and observability
route_domain "monitoring.myapp.com" do
  container "monitor1", "monitor1:7000"
  container "monitor2", "monitor2:7000"

  strategy :round_robin
  health_check "/monitor/health"
  ssl_config cert: "/certs/monitoring.myapp.com.pem", key: "/certs/monitoring.myapp.com.key"
  rate_limit requests: 50, window: 60_000
  monitor metrics: [:response_time, :error_rate, :system_metrics]
end

# Example 10: Backup/failover domain
route_domain "backup.myapp.com" do
  container "backup1", "backup1:8080"
  container "backup2", "backup2:8080"

  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate]
end

IO.puts("Load balancer configuration examples loaded!")
IO.puts("These examples demonstrate various configurations for different use cases.")
IO.puts("")
IO.puts("To use these in production:")
IO.puts("1. Copy the relevant examples to your config file")
IO.puts("2. Update domain names and container endpoints")
IO.puts("3. Adjust parameters based on your requirements")
IO.puts("4. Ensure SSL certificates are properly configured")
IO.puts("5. Set appropriate rate limits and health check paths")
