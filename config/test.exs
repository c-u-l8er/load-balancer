# Test environment configuration
import Config

# Configure the load balancer for testing
config :load_balancer,
  load_balancer_port: 8081,
  load_balancer_web_port: 4001,
  ssl_certs_path: "test/support/certs",
  log_level: :warn

# Configure the web endpoint for testing
config :load_balancer, LoadBalancerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  http: [port: 4001],
  secret_key_base: "test-secret-key-base-for-testing-only",
  live_view: [signing_salt: "test-signing-salt-for-testing-only"],
  server: false

# Configure the load balancer endpoint for testing
config :load_balancer, LoadBalancer.Endpoint,
  port: 8081

# Configure logging for testing
config :logger,
  level: :warn,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure health check intervals for testing
config :load_balancer, LoadBalancer.ContainerManager,
  health_check_interval: 10_000

# Configure rate limiting defaults for testing
config :load_balancer, LoadBalancer.RateLimiter,
  default_requests: 100,
  default_window: 60_000

# Configure SSL defaults for testing
config :load_balancer, LoadBalancer.SSL,
  default_cert_path: "test/support/certs/test.pem",
  default_key_path: "test/support/certs/test.key"

# Configure monitoring defaults for testing
config :load_balancer, LoadBalancer.Monitor,
  metrics_interval: 5_000,
  enable_prometheus: false

# Configure auto-scaling defaults for testing
config :load_balancer, LoadBalancer.AutoScaler,
  default_min_containers: 1,
  default_max_containers: 3,
  default_cpu_threshold: 80

# Configure circuit breaker defaults for testing
config :load_balancer, LoadBalancer.CircuitBreaker,
  default_threshold: 3,
  default_timeout: 30_000

# Configure session management defaults for testing
config :load_balancer, LoadBalancer.SessionManager,
  default_session_ttl: 1800,
  default_cookie_name: "test_session_id"

# Configure failover defaults for testing
config :load_balancer, LoadBalancer.Failover,
  default_health_check_path: "/test/health",
  default_failover_delay: 1000
