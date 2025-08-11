# This file is responsible for configuring your application
# and its dependencies with the aid of Config helpers.
import Config

# Configure the main application
config :load_balancer,
  load_balancer_port: String.to_integer(System.get_env("LOAD_BALANCER_PORT") || "8080"),
  load_balancer_web_port: String.to_integer(System.get_env("LOAD_BALANCER_WEB_PORT") || "4000"),
  ssl_certs_path: System.get_env("LOAD_BALANCER_SSL_CERTS_PATH") || "/etc/ssl/certs",
  log_level: String.to_atom(System.get_env("LOAD_BALANCER_LOG_LEVEL") || "info")

# Configure the web endpoint
config :load_balancer, LoadBalancerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  http: [
    port: String.to_integer(System.get_env("LOAD_BALANCER_WEB_PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "L47n8TRklPIz+kxPlZO9Ta6lukDTD9hOE/PvqqxJILEXvXlULPobBNYJSRXOAONE",
  live_view: [signing_salt: "zsAoodEZf6K3fZiNJt/5QrTFgSYJil/BjwxIX8O3Q1kp7xhBsyehDhOFt6I5S6w+"]

# Configure the load balancer endpoint
config :load_balancer, LoadBalancer.Endpoint,
  port: String.to_integer(System.get_env("LOAD_BALANCER_PORT") || "8080")

# Configure logging
config :logger,
  level: String.to_atom(System.get_env("LOAD_BALANCER_LOG_LEVEL") || "info"),
  format: "$time [$level] $message\n"

# Configure health check intervals
config :load_balancer, LoadBalancer.ContainerManager,
  health_check_interval: String.to_integer(System.get_env("HEALTH_CHECK_INTERVAL") || "30000")

# Configure rate limiting defaults
config :load_balancer, LoadBalancer.RateLimiter,
  default_requests: String.to_integer(System.get_env("DEFAULT_RATE_LIMIT") || "1000"),
  default_window: String.to_integer(System.get_env("DEFAULT_RATE_WINDOW") || "60000")

# Configure SSL defaults
config :load_balancer, LoadBalancer.SSL,
  default_cert_path: System.get_env("DEFAULT_SSL_CERT_PATH") || "/etc/ssl/certs/default.pem",
  default_key_path: System.get_env("DEFAULT_SSL_KEY_PATH") || "/etc/ssl/certs/default.key"

# Configure monitoring defaults
config :load_balancer, LoadBalancer.Monitor,
  metrics_interval: String.to_integer(System.get_env("METRICS_INTERVAL") || "10000"),
  enable_prometheus: String.to_atom(System.get_env("ENABLE_PROMETHEUS") || "false")

# Configure auto-scaling defaults
config :load_balancer, LoadBalancer.AutoScaler,
  default_min_containers: String.to_integer(System.get_env("DEFAULT_MIN_CONTAINERS") || "2"),
  default_max_containers: String.to_integer(System.get_env("DEFAULT_MAX_CONTAINERS") || "10"),
  default_cpu_threshold: String.to_integer(System.get_env("DEFAULT_CPU_THRESHOLD") || "80")

# Configure circuit breaker defaults
config :load_balancer, LoadBalancer.CircuitBreaker,
  default_threshold: String.to_integer(System.get_env("DEFAULT_CIRCUIT_BREAKER_THRESHOLD") || "5"),
  default_timeout: String.to_integer(System.get_env("DEFAULT_CIRCUIT_BREAKER_TIMEOUT") || "60000")

# Configure session management defaults
config :load_balancer, LoadBalancer.SessionManager,
  default_session_ttl: String.to_integer(System.get_env("DEFAULT_SESSION_TTL") || "3600"),
  default_cookie_name: System.get_env("DEFAULT_COOKIE_NAME") || "session_id"

# Configure failover defaults
config :load_balancer, LoadBalancer.Failover,
  default_health_check_path: System.get_env("DEFAULT_FAILOVER_HEALTH_CHECK") || "/health",
  default_failover_delay: String.to_integer(System.get_env("DEFAULT_FAILOVER_DELAY") || "5000")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
