# Production environment configuration
import Config

# Configure the load balancer for production
config :load_balancer,
  load_balancer_port: String.to_integer(System.get_env("LOAD_BALANCER_PORT") || "8080"),
  load_balancer_web_port: String.to_integer(System.get_env("LOAD_BALANCER_WEB_PORT") || "4000"),
  ssl_certs_path: System.get_env("LOAD_BALANCER_SSL_CERTS_PATH") || "/etc/ssl/certs",
  log_level: String.to_atom(System.get_env("LOAD_BALANCER_LOG_LEVEL") || "info")

# Configure the web endpoint for production
config :load_balancer, LoadBalancerWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  http: [
    port: String.to_integer(System.get_env("LOAD_BALANCER_WEB_PORT") || "4001"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "GnxSXgDYykilzlTlmuLmg8kmeW+e7wvDvNKfIoHnLkDOfinAX1cuEeitZ4Ae3UJAhZZJim+Bws6Zen352o2fTQ==",
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT") || "production-signing-salt"],
  server: true,
  code_reloader: false,
  check_origin: false

# Configure the load balancer endpoint for production
config :load_balancer, LoadBalancer.Endpoint,
  port: String.to_integer(System.get_env("LOAD_BALANCER_PORT") || "8080")

# Configure logging for production
config :logger,
  level: String.to_atom(System.get_env("LOAD_BALANCER_LOG_LEVEL") || "info"),
  format: "$time [$level] $message\n"

# Configure health check intervals for production
config :load_balancer, LoadBalancer.ContainerManager,
  health_check_interval: String.to_integer(System.get_env("HEALTH_CHECK_INTERVAL") || "30000")

# Configure rate limiting defaults for production
config :load_balancer, LoadBalancer.RateLimiter,
  default_requests: String.to_integer(System.get_env("DEFAULT_RATE_LIMIT") || "1000"),
  default_window: String.to_integer(System.get_env("DEFAULT_RATE_WINDOW") || "60000")

# Configure SSL defaults for production
config :load_balancer, LoadBalancer.SSL,
  default_cert_path: System.get_env("DEFAULT_SSL_CERT_PATH") || "/etc/ssl/certs/default.pem",
  default_key_path: System.get_env("DEFAULT_SSL_KEY_PATH") || "/etc/ssl/certs/default.key"

# Configure monitoring defaults for production
config :load_balancer, LoadBalancer.Monitor,
  metrics_interval: String.to_integer(System.get_env("METRICS_INTERVAL") || "10000"),
  enable_prometheus: String.to_atom(System.get_env("ENABLE_PROMETHEUS") || "true")

# Configure auto-scaling defaults for production
config :load_balancer, LoadBalancer.AutoScaler,
  default_min_containers: String.to_integer(System.get_env("DEFAULT_MIN_CONTAINERS") || "2"),
  default_max_containers: String.to_integer(System.get_env("DEFAULT_MAX_CONTAINERS") || "10"),
  default_cpu_threshold: String.to_integer(System.get_env("DEFAULT_CPU_THRESHOLD") || "80")

# Configure circuit breaker defaults for production
config :load_balancer, LoadBalancer.CircuitBreaker,
  default_threshold: String.to_integer(System.get_env("DEFAULT_CIRCUIT_BREAKER_THRESHOLD") || "5"),
  default_timeout: String.to_integer(System.get_env("DEFAULT_CIRCUIT_BREAKER_TIMEOUT") || "60000")

# Configure session management defaults for production
config :load_balancer, LoadBalancer.SessionManager,
  default_session_ttl: String.to_integer(System.get_env("DEFAULT_SESSION_TTL") || "3600"),
  default_cookie_name: System.get_env("DEFAULT_COOKIE_NAME") || "session_id"

# Configure failover defaults for production
config :load_balancer, LoadBalancer.Failover,
  default_health_check_path: System.get_env("DEFAULT_FAILOVER_HEALTH_CHECK") || "/health",
  default_failover_delay: String.to_integer(System.get_env("DEFAULT_FAILOVER_DELAY") || "5000")
