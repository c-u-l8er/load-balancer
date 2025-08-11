defmodule LoadBalancer.DomainStore do
  @moduledoc """
  Manages domain storage using ETS tables for fast in-memory access.
  Provides CRUD operations for domain configurations.
  """

  @table_name :domains

  @doc """
  Initializes the domain store by creating the ETS table.
  Called during application startup.
  """
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])

    # Add some sample domains for testing
    add_domain(%{
      domain: "myapp.local",
      containers: ["myapp-nginx"],
      strategy: "round_robin",
      health_check: "/",
      status: "active"
    })

    add_domain(%{
      domain: "nginx.local",
      containers: ["myapp-nginx"],
      strategy: "round_robin",
      health_check: "/",
      status: "active"
    })

    add_domain(%{
      domain: "lb.local",
      containers: ["load-balancer"],
      strategy: "round_robin",
      health_check: "/health",
      status: "active"
    })
  end

  @doc """
  Adds a new domain to the store.
  Returns {:ok, domain} on success or {:error, reason} on failure.
  """
  def add_domain(domain_data) do
    # Ensure the ETS table exists before trying to access it
    case :ets.info(@table_name) do
      :undefined ->
        init()
      _ ->
        :ok
    end

    # Validate the domain data
    case validate_domain_data(domain_data) do
      :ok ->
        # Check if domain already exists
        domain_name = get_field(domain_data, :domain) || get_field(domain_data, "domain")
        case get_domain(domain_name) do
          nil ->
            # Convert string keys to atoms and ensure containers is a list
            containers = case get_field(domain_data, :containers) || get_field(domain_data, "containers") do
              containers when is_list(containers) -> containers
              containers when is_binary(containers) ->
                containers
                |> String.split(",")
                |> Enum.map(&String.trim/1)
                |> Enum.filter(&(&1 != ""))
              _ -> []
            end

            domain = %{
              domain: domain_name,
              containers: containers,
              strategy: get_field(domain_data, :strategy) || get_field(domain_data, "strategy"),
              health_check: get_field(domain_data, :health_check) || get_field(domain_data, "health_check"),
              status: get_field(domain_data, :status) || get_field(domain_data, "status")
            }

            :ets.insert(@table_name, {domain.domain, domain})
            {:ok, domain}

          _existing ->
            {:error, "Domain already exists"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates an existing domain in the store.
  Returns {:ok, domain} on success or {:error, reason} on failure.
  """
  def update_domain(domain_name, domain_data) do
    # Ensure the ETS table exists before trying to access it
    case :ets.info(@table_name) do
      :undefined ->
        init()
      _ ->
        :ok
    end

    # Validate the domain data
    case validate_domain_data(domain_data) do
      :ok ->
        # Check if domain exists
        case get_domain(domain_name) do
          nil ->
            {:error, "Domain not found"}

          _existing ->
            # Convert string keys to atoms and ensure containers is a list
            containers = case get_field(domain_data, :containers) || get_field(domain_data, "containers") do
              containers when is_list(containers) -> containers
              containers when is_binary(containers) ->
                containers
                |> String.split(",")
                |> Enum.map(&String.trim/1)
                |> Enum.filter(&(&1 != ""))
              _ -> []
            end

            new_domain_name = get_field(domain_data, :domain) || get_field(domain_data, "domain")
            domain = %{
              domain: new_domain_name,
              containers: containers,
              strategy: get_field(domain_data, :strategy) || get_field(domain_data, "strategy"),
              health_check: get_field(domain_data, :health_check) || get_field(domain_data, "health_check"),
              status: get_field(domain_data, :status) || get_field(domain_data, "status")
            }

            # If the domain name changed, remove the old entry first
            if domain_name != new_domain_name do
              :ets.delete(@table_name, domain_name)
            end

            :ets.insert(@table_name, {domain.domain, domain})
            {:ok, domain}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Deletes a domain from the store.
  Returns {:ok, domain_name} on success or {:error, reason} on failure.
  """
  def delete_domain(domain_name) do
    # Ensure the ETS table exists before trying to access it
    case :ets.info(@table_name) do
      :undefined ->
        init()
        {:error, "Domain not found"}
      _ ->
        case get_domain(domain_name) do
          nil ->
            {:error, "Domain not found"}

          _domain ->
            :ets.delete(@table_name, domain_name)
            {:ok, domain_name}
        end
    end
  end

  @doc """
  Retrieves a domain by name.
  Returns the domain map or nil if not found.
  """
  def get_domain(domain_name) do
    # Ensure the ETS table exists before trying to access it
    case :ets.info(@table_name) do
      :undefined ->
        # Table doesn't exist, initialize it and return nil
        init()
        nil
      _ ->
        case :ets.lookup(@table_name, domain_name) do
          [{^domain_name, domain}] -> domain
          [] -> nil
        end
    end
  end

  @doc """
  Retrieves all domains from the store.
  Returns a list of domain maps.
  """
  def get_all_domains do
    # Ensure the ETS table exists before trying to access it
    case :ets.info(@table_name) do
      :undefined ->
        # Table doesn't exist, initialize it and return empty list
        init()
        []
      _ ->
        :ets.tab2list(@table_name)
        |> Enum.map(fn {_key, domain} -> domain end)
        |> Enum.sort_by(& &1.domain)
    end
  end

  @doc """
  Validates domain data structure and values.
  Returns :ok or {:error, reason}.
  """
  defp validate_domain_data(domain_data) do
    # Handle both string and atom keys
    domain = get_field(domain_data, :domain) || get_field(domain_data, "domain")
    containers = get_field(domain_data, :containers) || get_field(domain_data, "containers")
    strategy = get_field(domain_data, :strategy) || get_field(domain_data, "strategy")
    health_check = get_field(domain_data, :health_check) || get_field(domain_data, "health_check")
    status = get_field(domain_data, :status) || get_field(domain_data, "status")

    cond do
      is_nil(domain) or domain == "" ->
        {:error, "Domain name is required"}

      is_nil(containers) or
      (is_list(containers) and containers == []) or
      (is_binary(containers) and String.trim(containers) == "") ->
        {:error, "At least one container is required"}

      is_nil(strategy) or strategy == "" ->
        {:error, "Load balancing strategy is required"}

      is_nil(health_check) or health_check == "" ->
        {:error, "Health check path is required"}

      is_nil(status) or status == "" ->
        {:error, "Status is required"}

      not Enum.member?(["round_robin", "least_connections", "ip_hash", "weighted_round_robin"], strategy) ->
        {:error, "Invalid load balancing strategy"}

      not Enum.member?(["active", "inactive", "maintenance"], status) ->
        {:error, "Invalid status value"}

      true ->
        :ok
    end
  end

  # Helper function to get field value regardless of key type
  defp get_field(data, key) when is_atom(key) do
    Map.get(data, key)
  end

  defp get_field(data, key) when is_binary(key) do
    Map.get(data, key)
  end
end
