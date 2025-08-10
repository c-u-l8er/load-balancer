defmodule LoadBalancer.Config do
  @moduledoc """
  Configuration module demonstrating how to use the load balancer macros.
  This module shows how to define domain routes, containers, and various features.
  """

  import LoadBalancer.Macros
  require Logger

  # Example domain: example.com
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

  # Example domain: api.example.com
  route_domain "api.example.com" do
    container "api1", "api1:3000"
    container "api2", "api2:3000"
    strategy :least_connections
    health_check "/ping"
    rate_limit requests: 500, window: 60_000
    circuit_breaker threshold: 3, timeout: 30_000
    monitor metrics: [:response_time, :error_rate]
  end

  # Example domain: static.example.com
  route_domain "static.example.com" do
    container "cdn1", "cdn1:80"
    container "cdn2", "cdn2:80"
    strategy :ip_hash
    health_check "/health"
    ssl_config cert: "/certs/static.example.com.pem", key: "/certs/static.example.com.key"
    rate_limit requests: 2000, window: 60_000
  end

  # Example domain: admin.example.com
  route_domain "admin.example.com" do
    container "admin1", "admin1:9000"
    strategy :round_robin
    health_check "/admin/health"
    ssl_config cert: "/certs/admin.example.com.pem", key: "/certs/admin.example.com.key"
    rate_limit requests: 100, window: 60_000
    sticky_sessions cookie: "admin_session", ttl: 1800
    monitor metrics: [:response_time, :error_rate, :access_logs]
  end

  # Example domain: microservice.example.com
  route_domain "microservice.example.com" do
    container "service1", "service1:4000"
    container "service2", "service2:4000"
    container "service3", "service3:4000"
    strategy :weighted_round_robin
    health_check "/health"
    circuit_breaker threshold: 10, timeout: 120_000
    monitor metrics: [:response_time, :error_rate, :throughput, :queue_depth]
    auto_scale min: 3, max: 15, cpu_threshold: 70
  end

  # Example domain: legacy.example.com
  route_domain "legacy.example.com" do
    container "legacy1", "legacy1:8080"
    strategy :round_robin
    health_check "/status"
    failover backup_domain: "modern.example.com", health_check: "/health"
  end

  # Example domain: test.example.com (for development/testing)
  route_domain "test.example.com" do
    container "test1", "test1:5000"
    container "test2", "test2:5000"
    strategy :round_robin
    health_check "/test/health"
    monitor metrics: [:response_time, :error_rate]
  end

  # Example domain: staging.example.com
  route_domain "staging.example.com" do
    container "staging1", "staging1:6000"
    container "staging2", "staging2:6000"
    strategy :least_connections
    health_check "/staging/health"
    rate_limit requests: 200, window: 60_000
    monitor metrics: [:response_time, :error_rate, :throughput]
  end

  # Example domain: monitoring.example.com
  route_domain "monitoring.example.com" do
    container "monitor1", "monitor1:7000"
    container "monitor2", "monitor2:7000"
    strategy :round_robin
    health_check "/monitor/health"
    ssl_config cert: "/certs/monitoring.example.com.pem", key: "/certs/monitoring.example.com.key"
    rate_limit requests: 50, window: 60_000
    monitor metrics: [:response_time, :error_rate, :system_metrics]
  end

  # Example domain: backup.example.com (failover domain)
  route_domain "backup.example.com" do
    container "backup1", "backup1:8080"
    container "backup2", "backup2:8080"
    strategy :round_robin
    health_check "/health"
    monitor metrics: [:response_time, :error_rate]
  end

  @doc """
  Initialize the load balancer configuration.
  This function is called during application startup.
  """
  def init do
    Logger.info("Load balancer configuration initialized")
    :ok
  end

  @doc """
  Get the current configuration for all domains.
  """
  def get_configuration do
    LoadBalancer.Router.get_routes()
  end

  @doc """
  Update configuration for a specific domain.
  """
  def update_domain_config(domain, config) do
    LoadBalancer.Router.update_route(domain, config)
  end

  @doc """
  Add a new container to an existing domain.
  """
  def add_container_to_domain(domain, _container_name, container_endpoint) do
    LoadBalancer.Router.add_container(domain, container_endpoint)
  end

  @doc """
  Set the load balancing strategy for a domain.
  """
  def set_domain_strategy(domain, strategy) do
    LoadBalancer.Router.set_strategy(domain, strategy)
  end
end
