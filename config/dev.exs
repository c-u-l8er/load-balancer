# Development environment configuration
import Config

# Configure the load balancer for development
config :load_balancer,
  load_balancer_port: 8080,
  load_balancer_web_port: 4000,
  ssl_certs_path: "priv/certs",
  log_level: :debug

# Configure the web endpoint for development
config :load_balancer, LoadBalancerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  secret_key_base: "L47n8TRklPIz+kxPlZO9Ta6lukDTD9hOE/PvqqxJILEXvXlULPobBNYJSRXOAONE",
  live_view: [signing_salt: "zsAoodEZf6K3fZiNJt/5QrTFgSYJil/BjwxIX8O3Q1kp7xhBsyehDhOFt6I5S6w+"]

# Configure the load balancer endpoint for development
config :load_balancer, LoadBalancer.Endpoint,
  port: 8080

# Configure logging for development
config :logger,
  level: :debug,
  format: "$time [$level] $message\n"

# Configure health check intervals for development
config :load_balancer, LoadBalancer.ContainerManager,
  health_check_interval: 30_000

# Configure rate limiting defaults for development
config :load_balancer, LoadBalancer.RateLimiter,
  default_requests: 1000,
  default_window: 60_000

# Configure SSL defaults for development
config :load_balancer, LoadBalancer.SSL,
  default_cert_path: "priv/certs/dev.pem",
  default_key_path: "priv/certs/dev.key"

# Configure monitoring defaults for development
config :load_balancer, LoadBalancer.Monitor,
  metrics_interval: 10_000,
  enable_prometheus: false

# Configure auto-scaling defaults for development
config :load_balancer, LoadBalancer.AutoScaler,
  default_min_containers: 1,
  default_max_containers: 5,
  default_cpu_threshold: 80

# Configure circuit breaker defaults for development
config :load_balancer, LoadBalancer.CircuitBreaker,
  default_threshold: 5,
  default_timeout: 60_000

# Configure session management defaults for development
config :load_balancer, LoadBalancer.SessionManager,
  default_session_ttl: 3600,
  default_cookie_name: "session_id"

# Configure failover defaults for development
config :load_balancer, LoadBalancer.Failover,
  default_health_check_path: "/health",
  default_failover_delay: 5000
