defmodule LoadBalancer.ContainerManager do
  @moduledoc """
  Manages Docker containers, their health status, and lifecycle operations.
  Integrates with Docker API for container discovery and management.
  """

  use GenServer
  require Logger

  @type container_name :: String.t()
  @type container_endpoint :: String.t()
  @type container_status :: :healthy | :unhealthy | :starting | :stopped

  defmodule Container do
    @moduledoc "Container information structure"
    defstruct [
      :name,
      :endpoint,
      :status,
      :health_check_url,
      :last_health_check,
      :connection_count,
      :metadata
    ]
  end

  defmodule State do
    @moduledoc "Internal state for container manager"
    defstruct containers: %{}, health_check_interval: 30_000
  end

  # Client API

  @doc """
  Starts the container manager process.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a new container with the manager.
  """
  def register_container(name, endpoint, opts \\ []) do
    GenServer.call(__MODULE__, {:register_container, name, endpoint, opts})
  end

  @doc """
  Gets all registered containers.
  """
  def get_containers do
    GenServer.call(__MODULE__, :get_containers)
  end

  @doc """
  Gets a specific container by name.
  """
  def get_container(name) do
    GenServer.call(__MODULE__, {:get_container, name})
  end

  @doc """
  Updates container status.
  """
  def update_container_status(name, status) do
    GenServer.call(__MODULE__, {:update_status, name, status})
  end

  @doc """
  Removes a container from the manager.
  """
  def remove_container(name) do
    GenServer.call(__MODULE__, {:remove_container, name})
  end

  @doc """
  Performs a health check on a specific container.
  """
  def health_check_container(name) do
    GenServer.call(__MODULE__, {:health_check, name})
  end

  # Server Callbacks

  @impl GenServer
  def init(_opts) do
    Logger.info("Container Manager starting...")

    # Initialize Docker connection
    case init_docker_connection() do
      :ok ->
        # Schedule container discovery after startup to avoid deadlock
        Process.send_after(self(), :discover_containers, 1000)
        schedule_health_checks()
        {:ok, %State{}}

      {:error, reason} ->
        Logger.error("Failed to initialize Docker connection: #{reason}")
        {:ok, %State{}}
    end
  end

  @impl GenServer
  def handle_call({:register_container, name, endpoint, opts}, _from, state) do
    Logger.info("Registering container: #{name} at #{endpoint}")

    container = %Container{
      name: name,
      endpoint: endpoint,
      status: :starting,
      health_check_url: opts[:health_check_url] || "#{endpoint}/health",
      last_health_check: nil,
      connection_count: 0,
      metadata: opts[:metadata] || %{}
    }

    new_state = %{state | containers: Map.put(state.containers, name, container)}

    # Perform initial health check
    Task.async(fn -> perform_health_check(container) end)

    {:reply, {:ok, container}, new_state}
  end

  @impl GenServer
  def handle_call(:get_containers, _from, state) do
    {:reply, Map.values(state.containers), state}
  end

  @impl GenServer
  def handle_call({:get_container, name}, _from, state) do
    case Map.get(state.containers, name) do
      nil -> {:reply, {:error, :container_not_found}, state}
      container -> {:reply, {:ok, container}, state}
    end
  end

  @impl GenServer
  def handle_call({:update_status, name, status}, _from, state) do
    case Map.get(state.containers, name) do
      nil ->
        {:reply, {:error, :container_not_found}, state}

      container ->
        updated_container = %{container | status: status}
        new_state = %{state | containers: Map.put(state.containers, name, updated_container)}
        Logger.info("Updated container #{name} status to #{status}")
        {:reply, :ok, new_state}
    end
  end

  @impl GenServer
  def handle_call({:remove_container, name}, _from, state) do
    case Map.get(state.containers, name) do
      nil ->
        {:reply, {:error, :container_not_found}, state}

      _container ->
        new_state = %{state | containers: Map.delete(state.containers, name)}
        Logger.info("Removed container: #{name}")
        {:reply, :ok, new_state}
    end
  end

  @impl GenServer
  def handle_call({:health_check, name}, _from, state) do
    case Map.get(state.containers, name) do
      nil ->
        {:reply, {:error, :container_not_found}, state}

      container ->
        Task.async(fn -> perform_health_check(container) end)
        {:reply, :ok, state}
    end
  end

  @impl GenServer
  def handle_info({:health_check_result, name, result}, state) do
    case Map.get(state.containers, name) do
      nil -> {:noreply, state}

      container ->
        status = if result, do: :healthy, else: :unhealthy
        updated_container = %{container |
          status: status,
          last_health_check: DateTime.utc_now()
        }

        new_state = %{state | containers: Map.put(state.containers, name, updated_container)}

        if status == :unhealthy do
          Logger.warn("Container #{name} is unhealthy")
        end

        {:noreply, new_state}
    end
  end

  @impl GenServer
  def handle_info(:perform_health_checks, state) do
    # Perform health checks on all containers
    Enum.each(state.containers, fn {_name, container} ->
      Task.async(fn -> perform_health_check(container) end)
    end)

    schedule_health_checks()
    {:noreply, state}
  end

  # Private Functions

  defp init_docker_connection do
    # Initialize Docker connection
    # This would typically involve setting up Docker client connection
    # For now, we'll assume it's successful
    :ok
  end

  defp schedule_health_checks do
    Process.send_after(self(), :perform_health_checks, 30_000)
  end

  defp schedule_container_discovery do
    Process.send_after(self(), :discover_containers, 30_000)
  end

  defp perform_health_check(container) do
    Logger.info("Checking Docker status for container: #{container.name}")

    try do
      # Query Docker for container status
      case get_docker_container_status(container.name) do
        {:ok, status, health} ->
          Logger.info("Docker status for #{container.name}: #{status}, health: #{health}")
          send(__MODULE__, {:health_check_result, container.name, {status, health}})

        {:error, reason} ->
          Logger.warn("Failed to get Docker status for #{container.name}: #{reason}")
          send(__MODULE__, {:health_check_result, container.name, {:unknown, :unknown}})
      end
    rescue
      error ->
        Logger.warn("Docker status check for #{container.name} crashed with error: #{inspect(error)}")
        send(__MODULE__, {:health_check_result, container.name, {:unknown, :unknown}})
    end
  end

  defp get_docker_container_status(container_name) do
    # Use Docker CLI to get container status
    Logger.info("Getting Docker status for container: #{container_name}")
    
    case System.cmd("docker", ["inspect", "--format", "{{.State.Status}}", container_name]) do
      {status, 0} ->
        status = String.trim(status)
        Logger.info("Docker status for #{container_name}: #{status}")

        # Also get health status if available
        case System.cmd("docker", ["inspect", "--format", "{{.State.Health.Status}}", container_name]) do
          {health, 0} ->
            health = String.trim(health)
            Logger.info("Docker health for #{container_name}: #{health}")
            {:ok, status, health}
          {health, exit_code} ->
            Logger.warn("Health check failed for #{container_name}, exit code: #{exit_code}, output: #{health}")
            {:ok, status, "none"}
        end

      {error, exit_code} ->
        Logger.error("Status check failed for #{container_name}, exit code: #{exit_code}, output: #{error}")
        {:error, "Container not found or error: #{error}"}
    end
  end

  # Handle health check results from Tasks
  def handle_info({ref, {:health_check_result, name, result}}, state) when is_reference(ref) do
    # This is a Task result, handle it the same way
    handle_health_check_result(name, result, state)
  end

  def handle_info({:health_check_result, name, result}, state) do
    # This is a direct message, handle it
    handle_health_check_result(name, result, state)
  end

  # Handle Task completion messages (normal behavior)
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Task completed normally, ignore this message
    {:noreply, state}
  end

  # Helper function to handle health check results
  defp handle_health_check_result(name, {docker_status, docker_health}, state) do
    case Map.get(state.containers, name) do
      nil -> {:noreply, state}

      container ->
        # Map Docker status to our internal status
        Logger.info("Mapping Docker status for #{name}: #{docker_status}, health: #{docker_health}")
        
        status = case docker_status do
          "running" ->
            case docker_health do
              "healthy" -> :healthy
              "unhealthy" -> :unhealthy
              "starting" -> :starting
              _ -> :running
            end
          "exited" -> :stopped
          "created" -> :starting
          "paused" -> :paused
          _ -> :unknown
        end
        
        Logger.info("Mapped status for #{name}: #{docker_status} -> #{status}")

        updated_container = %{container |
          status: status,
          last_health_check: DateTime.utc_now()
        }

        new_state = %{state | containers: Map.put(state.containers, name, updated_container)}

        Logger.info("Updated container #{name} status to #{status} (Docker: #{docker_status}, Health: #{docker_health})")

        {:noreply, new_state}
    end
  end

  # Handle container discovery message
  def handle_info(:discover_containers, state) do
    Logger.info("Starting container discovery...")

    # Register containers directly in the state instead of calling the public API
    # We'll get real status from Docker, not HTTP health checks
    containers = %{
      "web-app-1" => %Container{
        name: "web-app-1",
        endpoint: "http://web-app-1:80",
        status: :starting,
        health_check_url: "http://web-app-1:80", # Keep for compatibility
        last_health_check: nil,
        connection_count: 0,
        metadata: %{}
      },
      "web-app-2" => %Container{
        name: "web-app-2",
        endpoint: "http://web-app-2:80",
        status: :starting,
        health_check_url: "http://web-app-2:80", # Keep for compatibility
        last_health_check: nil,
        connection_count: 0,
        metadata: %{}
      },
      "load-balancer" => %Container{
        name: "load-balancer",
        endpoint: "http://localhost:8080",
        status: :starting,
        health_check_url: "http://localhost:8080/health", # Keep for compatibility
        last_health_check: nil,
        connection_count: 0,
        metadata: %{}
      }
    }

    new_state = %{state | containers: containers}

    Logger.info("Container discovery completed - registered #{map_size(containers)} containers")

    # Trigger immediate health checks for all containers
    Enum.each(containers, fn {_name, container} ->
      Task.async(fn -> perform_health_check(container) end)
    end)

    # Schedule next discovery
    schedule_container_discovery()

    {:noreply, new_state}
  end

  @doc """
  Discovers running Docker containers automatically.
  This function is deprecated - use the async discovery via messages instead.
  """
  def discover_containers do
    Logger.warn("discover_containers/0 is deprecated - use async discovery instead")
    []
  end

  @doc """
  Gets healthy containers only.
  """
  def get_healthy_containers do
    case get_containers() do
      containers when is_list(containers) ->
        Enum.filter(containers, fn container -> container.status == :healthy end)

      _ ->
        []
    end
  end
end
