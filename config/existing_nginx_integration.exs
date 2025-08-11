# Existing Nginx + Portainer Extension Integration
# This file configures the load balancer to work with your existing nginx container

import LoadBalancer.Macros

# Route for your existing nginx container
route_domain "myapp.local" do
  container "myapp-nginx", "myapp-nginx:80"  # Use container name and internal port
  strategy :round_robin
  health_check "/"  # Use root path since no /health endpoint exists
  monitor metrics: [:response_time, :error_rate, :throughput]
end

# Route for your existing nginx container (alternative domain)
route_domain "nginx.local" do
  container "myapp-nginx", "myapp-nginx:80"
  strategy :round_robin
  health_check "/"
  monitor metrics: [:response_time, :error_rate]
end

# Route for load balancer management interface
route_domain "lb.local" do
  container "load-balancer", "load-balancer:4000"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate, :throughput]
end

# Route for testing with new web apps (optional)
route_domain "web.local" do
  container "web-app-1", "web-app-1:80"
  container "web-app-2", "web-app-2:80"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate, :throughput]
  sticky_sessions cookie: "web_session", ttl: 1800
end

# Individual web app routes
route_domain "web1.local" do
  container "web-app-1", "web-app-1:80"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate]
end

route_domain "web2.local" do
  container "web-app-2", "web-app-2:80"
  strategy :round_robin
  health_check "/health"
  monitor metrics: [:response_time, :error_rate]
end
