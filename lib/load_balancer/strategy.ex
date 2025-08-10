defmodule LoadBalancer.Strategy do
  @moduledoc """
  Load balancing strategies for distributing traffic across containers.
  Implements various algorithms like round-robin, least connections, and IP hash.
  """

  @type strategy :: :round_robin | :least_connections | :ip_hash | :weighted_round_robin
  @type container :: String.t()
  @type headers :: map()

  @doc """
  Selects a container based on the specified strategy.
  """
  def select_container(containers, strategy, headers \\ %{}) do
    case strategy do
      :round_robin -> round_robin(containers)
      :least_connections -> least_connections(containers)
      :ip_hash -> ip_hash(containers, headers)
      :weighted_round_robin -> weighted_round_robin(containers)
      _ -> {:error, :unsupported_strategy}
    end
  end

  @doc """
  Round-robin strategy: distributes requests evenly across containers.
  """
  def round_robin(containers) do
    case get_next_round_robin_index(containers) do
      {:ok, index} -> {:ok, Enum.at(containers, index)}
      error -> error
    end
  end

  @doc """
  Least connections strategy: routes to the container with the fewest active connections.
  """
  def least_connections(containers) do
    case get_least_connections_container(containers) do
      {:ok, container} -> {:ok, container}
      error -> error
    end
  end

  @doc """
  IP hash strategy: consistently routes requests from the same IP to the same container.
  """
  def ip_hash(containers, headers) do
    case extract_client_ip(headers) do
      {:ok, ip} ->
        index = :erlang.phash2(ip, length(containers))
        {:ok, Enum.at(containers, index)}

      {:error, _} ->
        # Fallback to round-robin if IP extraction fails
        round_robin(containers)
    end
  end

  @doc """
  Weighted round-robin strategy: distributes requests based on container weights.
  """
  def weighted_round_robin(containers) do
    case get_next_weighted_round_robin_container(containers) do
      {:ok, container} -> {:ok, container}
      error -> error
    end
  end

  # Private Functions

  defp get_next_round_robin_index(containers) do
    case :ets.lookup(:load_balancer_counters, :round_robin) do
      [] ->
        :ets.insert(:load_balancer_counters, {:round_robin, 0})
        {:ok, 0}

      [{:round_robin, current_index}] ->
        next_index = rem(current_index + 1, length(containers))
        :ets.insert(:load_balancer_counters, {:round_robin, next_index})
        {:ok, next_index}
    end
  end

  defp get_least_connections_container(containers) do
    case get_container_connection_counts(containers) do
      [] -> {:error, :no_containers_available}
      counts ->
        {container, _count} = Enum.min_by(counts, fn {_container, count} -> count end)
        {:ok, container}
    end
  end

  defp get_container_connection_counts(containers) do
    Enum.map(containers, fn container ->
      count = get_container_connection_count(container)
      {container, count}
    end)
  end

  defp get_container_connection_count(container) do
    case :ets.lookup(:load_balancer_connections, container) do
      [] -> 0
      [{^container, count}] -> count
    end
  end

  defp get_next_weighted_round_robin_container(containers) do
    # For now, assume equal weights. In a real implementation,
    # containers would have weight metadata
    round_robin(containers)
  end

  defp extract_client_ip(headers) do
    # Try to extract IP from various headers
    cond do
      ip = headers["x-forwarded-for"] -> {:ok, ip}
      ip = headers["x-real-ip"] -> {:ok, ip}
      ip = headers["x-client-ip"] -> {:ok, ip}
      ip = headers["cf-connecting-ip"] -> {:ok, ip}
      true -> {:error, :no_ip_found}
    end
  end

  @doc """
  Increments the connection count for a container.
  """
  def increment_connection_count(container) do
    case :ets.lookup(:load_balancer_connections, container) do
      [] -> :ets.insert(:load_balancer_connections, {container, 1})
      [{^container, count}] -> :ets.insert(:load_balancer_connections, {container, count + 1})
    end
  end

  @doc """
  Decrements the connection count for a container.
  """
  def decrement_connection_count(container) do
    case :ets.lookup(:load_balancer_connections, container) do
      [] -> :ok
      [{^container, count}] when count > 0 ->
        :ets.insert(:load_balancer_connections, {container, count - 1})
      _ -> :ok
    end
  end

  @doc """
  Initializes the strategy system.
  """
  def init do
    :ets.new(:load_balancer_counters, [:set, :public, :named_table])
    :ets.new(:load_balancer_connections, [:set, :public, :named_table])
    :ok
  end
end
