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
          Logger.warning("Container #{name} is unhealthy")
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

  defp perform_health_check(container) do
    try do
      # Perform HTTP health check
      case HTTPoison.get(container.health_check_url, [], timeout: 5000) do
        {:ok, %{status_code: status_code}} when status_code in 200..299 ->
          send(__MODULE__, {:health_check_result, container.name, true})

        _ ->
          send(__MODULE__, {:health_check_result, container.name, false})
      end
    rescue
      _ ->
        send(__MODULE__, {:health_check_result, container.name, false})
    end
  end

  @doc """
  Discovers running Docker containers automatically.
  """
  def discover_containers do
    # This would integrate with Docker API to discover running containers
    # For now, return empty list
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
