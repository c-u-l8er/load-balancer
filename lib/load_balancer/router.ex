defmodule LoadBalancer.Router do
  @moduledoc """
  Main router for handling domain-based traffic routing to Docker containers.
  Integrates with the load balancing system and container management.
  """

  use GenServer
  require Logger

  @type domain :: String.t()
  @type container_endpoint :: String.t()
  @type route_config :: map()

  defmodule State do
    @moduledoc "Internal state for the router"
    defstruct domains: %{}, containers: %{}, strategies: %{}, health_checks: %{}
  end

  # Client API

  @doc """
  Starts the router process.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a domain with the router.
  """
  def register_domain(domain) do
    GenServer.call(__MODULE__, {:register_domain, domain})
  end

  @doc """
  Registers a domain with the router using existing configuration.
  """
  def register_domain_with_config(domain, config) do
    GenServer.call(__MODULE__, {:register_domain_with_config, domain, config})
  end

  @doc """
  Routes a request to the appropriate container based on domain.
  """
  def route_request(domain, path, headers \\ %{}) do
    GenServer.call(__MODULE__, {:route_request, domain, path, headers})
  end

  @doc """
  Gets the current routing configuration.
  """
  def get_routes do
    GenServer.call(__MODULE__, :get_routes)
  end

  @doc """
  Updates the routing configuration for a domain.
  """
  def update_route(domain, config) do
    GenServer.call(__MODULE__, {:update_route, domain, config})
  end

  # Server Callbacks

  @impl GenServer
  def init(_opts) do
    Logger.info("LoadBalancer Router starting...")
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:register_domain, domain}, _from, state) do
    Logger.info("Registering domain: #{domain}")

    new_state = %{state |
      domains: Map.put(state.domains, domain, %{
        containers: [],
        strategy: :round_robin,
        health_checks: [],
        ssl: nil,
        rate_limits: nil,
        sticky_sessions: nil,
        circuit_breaker: nil,
        monitoring: nil,
        auto_scaling: nil,
        failover: nil
      })
    }

    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:register_domain_with_config, domain, config}, _from, state) do
    Logger.info("Registering domain with config: #{domain}")

    # Convert string keys to atoms for strategy
    strategy = case config["strategy"] || config[:strategy] do
      "round_robin" -> :round_robin
      "least_connections" -> :least_connections
      "ip_hash" -> :ip_hash
      "weighted_round_robin" -> :weighted_round_robin
      _ -> :round_robin
    end

    new_state = %{state |
      domains: Map.put(state.domains, domain, %{
        containers: config["containers"] || config[:containers] || [],
        strategy: strategy,
        health_checks: [config["health_check"] || config[:health_check] || "/"],
        ssl: nil,
        rate_limits: nil,
        sticky_sessions: nil,
        circuit_breaker: nil,
        monitoring: nil,
        auto_scaling: nil,
        failover: nil
      })
    }

    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:route_request, domain, path, headers}, _from, state) do
    case Map.get(state.domains, domain) do
      nil ->
        Logger.warning("Domain not found: #{domain}")
        {:reply, {:error, :domain_not_found}, state}

      domain_config ->
        case select_container(domain_config, headers) do
          {:ok, container} ->
            Logger.debug("Routing #{domain}#{path} to #{container}")
            {:reply, {:ok, container}, state}

          {:error, reason} ->
            Logger.error("Failed to route request: #{reason}")
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl GenServer
  def handle_call(:get_routes, _from, state) do
    {:reply, state.domains, state}
  end

  @impl GenServer
  def handle_call({:update_route, domain, config}, _from, state) do
    case Map.get(state.domains, domain) do
      nil ->
        {:reply, {:error, :domain_not_found}, state}

      existing_config ->
        updated_config = Map.merge(existing_config, config)
        new_state = %{state | domains: Map.put(state.domains, domain, updated_config)}
        Logger.info("Updated route configuration for #{domain}")
        {:reply, :ok, new_state}
    end
  end

  @impl GenServer
  def handle_call({:add_container, domain, container}, _from, state) do
    case Map.get(state.domains, domain) do
      nil ->
        {:reply, {:error, :domain_not_found}, state}

      domain_config ->
        updated_containers = [container | domain_config.containers]
        updated_config = %{domain_config | containers: updated_containers}
        new_state = %{state | domains: Map.put(state.domains, domain, updated_config)}
        Logger.info("Added container #{container} to domain #{domain}")
        {:reply, :ok, new_state}
    end
  end

  @impl GenServer
  def handle_call({:set_strategy, domain, strategy}, _from, state) do
    case Map.get(state.domains, domain) do
      nil ->
        {:reply, {:error, :domain_not_found}, state}

      domain_config ->
        updated_config = %{domain_config | strategy: strategy}
        new_state = %{state | domains: Map.put(state.domains, domain, updated_config)}
        Logger.info("Set strategy #{strategy} for domain #{domain}")
        {:reply, :ok, new_state}
    end
  end

  # Private Functions

  defp select_container(domain_config, headers) do
    case domain_config.containers do
      [] ->
        {:error, :no_containers_available}

      containers ->
        strategy = domain_config.strategy || :round_robin
        LoadBalancer.Strategy.select_container(containers, strategy, headers)
    end
  end
end
