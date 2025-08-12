defmodule LoadBalancer.DomainPersistence do
  @moduledoc """
  Handles persistence of domain configurations to/from JSON files.
  This allows the ETS-based domain store to survive application restarts.
  """

  require Logger

  @data_file System.get_env("DOMAIN_DATA_PATH") || "data/domains.json"

  @doc """
  Saves all domains from the domain store to a JSON file.
  Called during application shutdown or periodically.
  """
  def save_domains do
    domains = LoadBalancer.DomainStore.get_all_domains()
    Logger.info("Saving #{length(domains)} domains to #{@data_file}")
    Logger.info("Domains to save: #{inspect(domains)}")

    # Ensure the data directory exists
    File.mkdir_p(Path.dirname(@data_file))

    # Convert domains to a serializable format
    serializable_domains = Enum.map(domains, fn domain ->
      %{
        domain: domain.domain,
        containers: domain.containers,
        strategy: domain.strategy,
        health_check: domain.health_check,
        status: domain.status
      }
    end)

    Logger.info("Serializable domains: #{inspect(serializable_domains)}")

    case File.write(@data_file, Jason.encode!(serializable_domains, pretty: true)) do
      :ok ->
        Logger.info("Domains saved to #{@data_file}")
        {:ok, length(domains)}
      {:error, reason} ->
        Logger.error("Failed to save domains: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Loads domains from the JSON file into the domain store.
  Called during application startup.
  """
  def load_domains do
    Logger.info("Attempting to load domains from: #{@data_file}")
    case File.read(@data_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, domains} ->
            # Clear existing domains first
            clear_existing_domains()

            # Load each domain
            loaded_count = Enum.reduce_while(domains, 0, fn domain_data, count ->
              case LoadBalancer.DomainStore.add_domain(domain_data) do
                {:ok, _domain} ->
                  # Also register the domain with the router
                  case LoadBalancer.Router.register_domain_with_config(domain_data["domain"], domain_data) do
                    :ok ->
                      Logger.info("Registered domain #{domain_data["domain"]} with router")
                    {:error, reason} ->
                      Logger.warn("Failed to register domain #{domain_data["domain"]} with router: #{reason}")
                  end
                  {:cont, count + 1}
                {:error, reason} ->
                  Logger.warn("Failed to load domain #{domain_data["domain"]}: #{reason}")
                  {:cont, count}
              end
            end)

            Logger.info("Loaded #{loaded_count} domains from #{@data_file}")
            {:ok, loaded_count}

          {:error, reason} ->
            Logger.error("Failed to parse domains file: #{reason}")
            {:error, reason}
        end

      {:error, :enoent} ->
        Logger.info("No domains file found at #{@data_file}, starting with empty store")
        {:ok, 0}

      {:error, reason} ->
        Logger.error("Failed to read domains file: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Clears all existing domains from the store.
  Used when reloading from file to avoid duplicates.
  """
  defp clear_existing_domains do
    # Clear the ETS table and recreate it without sample data
    :ets.delete(:domains)
    :ets.new(:domains, [:set, :public, :named_table])
  end

  @doc """
  Sets up automatic saving of domains every N seconds.
  This ensures data is persisted even if the application crashes.
  """
  def start_auto_save(interval_seconds \\ 30) do
    spawn(fn -> auto_save_loop(interval_seconds) end)
  end

  defp auto_save_loop(interval_seconds) do
    Process.sleep(interval_seconds * 1000)
    save_domains()
    auto_save_loop(interval_seconds)
  end
end
