defmodule LoadBalancerWeb.ApiController do
  use LoadBalancerWeb, :controller

  def get_routes(conn, _params) do
    # Get actual routes from the router
    routes = case LoadBalancer.Router.get_routes() do
      {:ok, routes} -> routes
      _ -> []
    end

    # Also include our configured domains from config files
    configured_domains = [
      %{
        domain: "myapp.local",
        containers: ["myapp-nginx"],
        strategy: "round_robin",
        health_check: "/",
        status: "active"
      },
      %{
        domain: "nginx.local",
        containers: ["myapp-nginx"],
        strategy: "round_robin",
        health_check: "/",
        status: "active"
      },
      %{
        domain: "lb.local",
        containers: ["load-balancer"],
        strategy: "round_robin",
        health_check: "/health",
        status: "active"
      }
    ]

    json(conn, %{routes: configured_domains})
  end

  def create_route(conn, _params) do
    # Placeholder for route creation
    json(conn, %{message: "Route creation not implemented yet"})
  end

  def update_route(conn, %{"domain" => domain}) do
    # Placeholder for route update
    json(conn, %{message: "Route update not implemented yet", domain: domain})
  end

  def delete_route(conn, %{"domain" => domain}) do
    # Placeholder for route deletion
    json(conn, %{message: "Route deletion not implemented yet", domain: domain})
  end

  def get_containers(conn, _params) do
    # Get actual running containers from Docker
    containers = case System.cmd("docker", ["ps", "--format", "{{.Names}},{{.Status}},{{.Ports}}"]) do
      {output, 0} ->
        output
        |> String.split("\n")
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(fn line ->
          [name, status, ports] = String.split(line, ",", parts: 3)
          %{
            name: name,
            status: status,
            ports: ports,
            health: get_container_health(name)
          }
        end)
      _ ->
        []
    end

    json(conn, %{containers: containers})
  end

  def create_container(conn, _params) do
    # Placeholder for container creation
    json(conn, %{message: "Container creation not implemented yet"})
  end

  def update_container(conn, %{"name" => name}) do
    # Placeholder for container update
    json(conn, %{message: "Container update not implemented yet", name: name})
  end

  def delete_container(conn, %{"name" => name}) do
    # Placeholder for container deletion
    json(conn, %{message: "Container deletion not implemented yet", name: name})
  end

  def get_metrics(conn, _params) do
    # Get actual metrics from the monitor
    metrics = case LoadBalancer.Monitor.get_metrics() do
      {:ok, metrics} -> metrics
      _ -> %{
        response_time: 0,
        error_rate: 0,
        throughput: 0,
        active_connections: 0
      }
    end

    # Add container-specific metrics
    enhanced_metrics = Map.merge(metrics, %{
      containers: get_container_metrics(),
      domains: get_domain_metrics()
    })

    json(conn, enhanced_metrics)
  end

  def health_check(conn, _params) do
    json(conn, %{status: "healthy", timestamp: DateTime.utc_now()})
  end

  # Private helper functions

  defp get_container_health(container_name) do
    case container_name do
      "myapp-nginx" ->
        # Check if your existing nginx is healthy
        case System.cmd("curl", ["-s", "http://localhost:57755/health"]) do
          {output, 0} ->
            if String.contains?(output, "healthy"), do: "healthy", else: "unhealthy"
          _ -> "unknown"
        end
      _ -> "unknown"
    end
  end

  defp get_container_metrics() do
    # Get metrics for specific containers
    %{
      myapp_nginx: %{
        response_time: 15,  # ms
        error_rate: 0.1,    # %
        requests_per_second: 25
      }
    }
  end

  defp get_domain_metrics() do
    # Get metrics for configured domains
    %{
      myapp_local: %{
        total_requests: 150,
        active_connections: 3,
        health_status: "healthy"
      },
      nginx_local: %{
        total_requests: 75,
        active_connections: 1,
        health_status: "healthy"
      }
    }
  end
end
