defmodule LoadBalancerWeb.ApiController do
  use LoadBalancerWeb, :controller

  def get_routes(conn, _params) do
    # Get actual routes from the router
    routes = case LoadBalancer.Router.get_routes() do
      {:ok, routes} -> routes
      _ -> []
    end

    # Get configured domains from the domain store
    configured_domains = LoadBalancer.DomainStore.get_all_domains()

    json(conn, %{routes: configured_domains})
  end

  def create_route(conn, params) do
    # Extract domain data from params
    domain_data = %{
      domain: params["domain"],
      containers: params["containers"],
      strategy: params["strategy"],
      health_check: params["health_check"],
      status: params["status"]
    }

    # Use the domain store to create the domain
    case LoadBalancer.DomainStore.add_domain(domain_data) do
      {:ok, domain} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Domain created successfully", domain: domain})

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def update_route(conn, %{"domain" => old_domain} = params) do
    # Extract updated domain data
    domain_data = %{
      domain: params["domain"],
      containers: params["containers"],
      strategy: params["strategy"],
      health_check: params["health_check"],
      status: params["status"]
    }

    # Use the domain store to update the domain
    case LoadBalancer.DomainStore.update_domain(old_domain, domain_data) do
      {:ok, domain} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Domain updated successfully", domain: domain})

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def delete_route(conn, %{"domain" => domain}) do
    # Use the domain store to delete the domain
    case LoadBalancer.DomainStore.delete_domain(domain) do
      {:ok, domain_name} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Domain deleted successfully", domain: domain_name})

      {:error, message} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: message})
    end
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

  defp validate_domain_data(domain_data) do
    cond do
      is_nil(domain_data.domain) or domain_data.domain == "" ->
        {:error, "Domain name is required"}

      is_nil(domain_data.containers) or domain_data.containers == [] ->
        {:error, "At least one container is required"}

      is_nil(domain_data.strategy) or domain_data.strategy == "" ->
        {:error, "Load balancing strategy is required"}

      is_nil(domain_data.health_check) or domain_data.health_check == "" ->
        {:error, "Health check path is required"}

      is_nil(domain_data.status) or domain_data.status == "" ->
        {:error, "Status is required"}

      not Enum.member?(["round_robin", "least_connections", "ip_hash", "weighted_round_robin"], domain_data.strategy) ->
        {:error, "Invalid load balancing strategy"}

      not Enum.member?(["active", "inactive", "maintenance"], domain_data.status) ->
        {:error, "Invalid status value"}

      true ->
        :ok
    end
  end
end
