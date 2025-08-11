# Portainer Integration Configuration
# This file configures the load balancer to work with Portainer and test applications

import LoadBalancer.Macros

# Route for test web applications (load balanced)
route_domain "web.local" do
  container "web-app-1", "web-app-1:80"
  container "web-app-2", "web-app-2:80"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate, :throughput]
  sticky_sessions cookie: "web_session", ttl: 1800
end

# Route for individual web app 1
route_domain "web1.local" do
  container "web-app-1", "web-app-1:80"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate]
end

# Route for individual web app 2
route_domain "web2.local" do
  container "web-app-2", "web-app-2:80"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate]
end

# Route for load balancer management interface
route_domain "lb.local" do
  container "load-balancer", "load-balancer:4000"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate, :throughput]
end

# Route for API testing
route_domain "api.local" do
  container "web-app-1", "web-app-1:80"
  container "web-app-2", "web-app-2:80"
  strategy :least_connections
  health_check "/health"
  rate_limit requests: 100, window: 60_000
  circuit_breaker threshold: 5, timeout: 30_000
  monitor metrics: [:response_time, :error_rate, :throughput]
end
