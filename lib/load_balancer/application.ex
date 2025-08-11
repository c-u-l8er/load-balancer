defmodule LoadBalancer.Application do
  @moduledoc """
  Main application module for the load balancer system.
  Starts and supervises all the load balancer services.
  """

  use Application
  require Logger

  @impl Application
  def start(_type, _args) do
    Logger.info("Starting LoadBalancer Application...")

    # Initialize ETS tables for strategies
    LoadBalancer.Strategy.init()

    # Initialize load balancer configuration
    LoadBalancer.Config.init()

    # Initialize domain store
    LoadBalancer.DomainStore.init()

    # Load persisted domains from file
    LoadBalancer.DomainPersistence.load_domains()

    # Start auto-saving domains every 30 seconds
    LoadBalancer.DomainPersistence.start_auto_save(30)

    children = [
      # Core load balancer services (GenServer processes)
      LoadBalancer.Router,
      LoadBalancer.ContainerManager,
      LoadBalancer.HealthChecker,

      # HTTP server for the load balancer
      {Plug.Cowboy, scheme: :http, plug: LoadBalancer.Endpoint, options: [port: Application.get_env(:load_balancer, :load_balancer_port)]},

      # Phoenix endpoint for management interface
      LoadBalancerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: LoadBalancer.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("LoadBalancer Application started successfully")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("Failed to start LoadBalancer Application: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl Application
  def stop(_state) do
    Logger.info("Stopping LoadBalancer Application...")

    # Save domains before shutting down
    case LoadBalancer.DomainPersistence.save_domains() do
      {:ok, count} -> Logger.info("Saved #{count} domains before shutdown")
      {:error, reason} -> Logger.error("Failed to save domains on shutdown: #{reason}")
    end

    :ok
  end
end
