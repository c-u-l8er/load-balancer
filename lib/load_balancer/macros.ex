defmodule LoadBalancer.Macros do
  @moduledoc """
  Core macros for the load balancer system.
  These macros provide domain-based routing and Docker container management.
  """

  @doc """
  Macro to define a domain route with automatic load balancing.

  ## Usage
      route_domain "example.com" do
        container "app1", "app1:8080"
        container "app2", "app2:8080"
        strategy :round_robin
        health_check "/health"
      end
  """
  defmacro route_domain(domain, do: block) do
    quote do
      def __route_domain__(unquote(domain)) do
        LoadBalancer.Router.register_domain(unquote(domain))
        unquote(block)
      end
    end
  end

  @doc """
  Macro to define a Docker container endpoint.

  ## Usage
      container "app1", "app1:8080"
  """
  defmacro container(name, endpoint) do
    quote do
      LoadBalancer.ContainerManager.register_container(unquote(name), unquote(endpoint))
    end
  end

  @doc """
  Macro to set the load balancing strategy for a domain.

  ## Usage
      strategy :round_robin
      strategy :least_connections
      strategy :ip_hash
  """
  defmacro strategy(strategy) do
    quote do
      LoadBalancer.Strategy.set_strategy(unquote(strategy))
    end
  end

  @doc """
  Macro to define health check endpoints for containers.

  ## Usage
      health_check "/health"
      health_check "/ping", interval: 30_000
  """
  defmacro health_check(path, opts \\ []) do
    quote do
      LoadBalancer.HealthChecker.add_health_check(unquote(path), unquote(opts))
    end
  end

  @doc """
  Macro to define SSL/TLS configuration for a domain.

  ## Usage
      ssl_config cert: "/path/to/cert.pem", key: "/path/to/key.pem"
  """
  defmacro ssl_config(opts) do
    quote do
      LoadBalancer.SSL.configure(unquote(opts))
    end
  end

  @doc """
  Macro to define rate limiting for a domain.

  ## Usage
      rate_limit requests: 100, window: 60_000
  """
  defmacro rate_limit(opts) do
    quote do
      LoadBalancer.RateLimiter.configure(unquote(opts))
    end
  end

  @doc """
  Macro to define sticky sessions configuration.

  ## Usage
      sticky_sessions cookie: "session_id", ttl: 3600
  """
  defmacro sticky_sessions(opts) do
    quote do
      LoadBalancer.SessionManager.configure_sticky(unquote(opts))
    end
  end

  @doc """
  Macro to define circuit breaker configuration.

  ## Usage
      circuit_breaker threshold: 5, timeout: 60_000
  """
  defmacro circuit_breaker(opts) do
    quote do
      LoadBalancer.CircuitBreaker.configure(unquote(opts))
    end
  end

  @doc """
  Macro to define monitoring and metrics collection.

  ## Usage
      monitor metrics: [:response_time, :error_rate, :throughput]
  """
  defmacro monitor(opts) do
    quote do
      LoadBalancer.Monitor.configure(unquote(opts))
    end
  end

  @doc """
  Macro to define automatic scaling rules.

  ## Usage
      auto_scale min: 2, max: 10, cpu_threshold: 80
  """
  defmacro auto_scale(opts) do
    quote do
      LoadBalancer.AutoScaler.configure(unquote(opts))
    end
  end

  @doc """
  Macro to define backup and failover configuration.

  ## Usage
      failover backup_domain: "backup.example.com", health_check: "/health"
  """
  defmacro failover(opts) do
    quote do
      LoadBalancer.Failover.configure(unquote(opts))
    end
  end
end
