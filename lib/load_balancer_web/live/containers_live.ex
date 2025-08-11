defmodule LoadBalancerWeb.ContainersLive do
  use LoadBalancerWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Schedule periodic updates
      :timer.send_interval(5000, self(), :update_containers)
      # Get initial data
      send(self(), :update_containers)
    end

    {:ok, assign(socket,
      page_title: "Containers",
      containers: [],
      loading: true
    )}
  end

  def handle_info(:update_containers, socket) do
    containers = fetch_containers()
    {:noreply, assign(socket, containers: containers, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Hero Section -->
      <div class="text-center space-y-4">
        <h1 class="text-5xl font-bold text-slate-900">
          Container Management
        </h1>
        <p class="text-xl text-slate-600 max-w-2xl mx-auto">
          Deploy, monitor, and manage your containerized applications with ease
        </p>
      </div>

      <!-- Loading State -->
      <%= if @loading do %>
        <div class="text-center py-12">
          <div class="inline-flex items-center px-4 py-2 font-semibold leading-6 text-slate-700 bg-slate-100 rounded-lg">
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-slate-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Loading container data...
          </div>
        </div>
      <% else %>
        <!-- Container Stats -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900"><%= length(@containers) %></div>
            <div class="text-sm text-slate-600">Total Containers</div>
          </div>

          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900">
              <%= @containers |> Enum.filter(&(&1["health"] == "running")) |> length() %>
            </div>
            <div class="text-sm text-slate-600">Running</div>
          </div>

          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 0 4 4m4-4l-4-4"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900">
              <%= @containers |> Enum.filter(&(&1["health"] == "healthy")) |> length() %>
            </div>
            <div class="text-sm text-slate-600">Healthy</div>
          </div>

          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-red-500 to-pink-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900">
              <%= @containers |> Enum.filter(&(&1["health"] in ["stopped", "exited", "unhealthy"])) |> length() %>
            </div>
            <div class="text-sm text-slate-600">Stopped/Error</div>
          </div>
        </div>

        <!-- Main Container Section -->
        <div class="enterprise-card p-8">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center space-x-4">
              <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center shadow-md">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                </svg>
              </div>
              <div>
                <h3 class="text-2xl font-bold text-slate-900">Active Containers</h3>
                <p class="text-slate-600">Manage your running containers</p>
              </div>
            </div>
            <button class="enterprise-button">
              Deploy New
            </button>
          </div>

          <!-- Container List -->
          <%= if Enum.empty?(@containers) do %>
            <!-- Empty State -->
            <div class="text-center py-12">
              <div class="w-24 h-24 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-12 h-12 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                </svg>
              </div>
              <h3 class="text-lg font-medium text-slate-900 mb-2">No containers found</h3>
              <p class="text-slate-600">Start by deploying your first container or check your Docker setup.</p>
            </div>
          <% else %>
            <!-- Container Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for container <- @containers do %>
                <div class="bg-slate-50 border border-slate-200 rounded-xl p-6 hover:bg-slate-100 transition-all duration-300">
                  <div class="flex items-start justify-between mb-4">
                    <div class="flex items-center space-x-3">
                      <div class={[
                        "w-3 h-3 rounded-full",
                        case container["health"] do
                          "healthy" -> "bg-green-500"
                          "running" -> "bg-blue-500"
                          "starting" -> "bg-yellow-500"
                          "unhealthy" -> "bg-red-500"
                          "stopped" -> "bg-slate-500"
                          "exited" -> "bg-red-500"
                          "paused" -> "bg-orange-500"
                          _ -> "bg-yellow-500"
                        end
                      ]}></div>
                      <h4 class="text-lg font-semibold text-slate-900"><%= container["name"] %></h4>
                    </div>
                    <div class="flex space-x-2">
                      <button class="p-2 text-slate-400 hover:text-slate-600 transition-colors">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
                        </svg>
                      </button>
                      <button class="p-2 text-slate-400 hover:text-slate-600 transition-colors">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                        </svg>
                      </button>
                    </div>
                  </div>

                  <div class="space-y-3">
                    <div class="flex items-center justify-between">
                      <span class="text-sm text-slate-600">Status</span>
                      <span class={[
                        "status-indicator",
                        case container["health"] do
                          "healthy" -> "status-healthy"
                          "running" -> "status-healthy"
                          "starting" -> "status-warning"
                          "unhealthy" -> "status-error"
                          "stopped" -> "status-error"
                          "exited" -> "status-error"
                          "paused" -> "status-warning"
                          _ -> "status-warning"
                        end
                      ]}>
                        <%= container["health"] %>
                      </span>
                    </div>

                    <div class="flex items-center justify-between">
                      <span class="text-sm text-slate-600">Ports</span>
                      <span class="text-sm text-slate-900 font-mono"><%= container["ports"] %></span>
                    </div>

                    <div class="flex items-center justify-between">
                      <span class="text-sm text-slate-600">State</span>
                      <span class="text-sm text-slate-900"><%= container["status"] %></span>
                    </div>
                  </div>

                  <div class="mt-4 pt-4 border-t border-slate-200">
                    <div class="flex space-x-2">
                      <button class="flex-1 enterprise-button-secondary text-sm py-2 px-3">
                        Restart
                      </button>
                      <button class="flex-1 enterprise-button-secondary text-sm py-2 px-3">
                        Logs
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Private helper functions

  defp fetch_containers() do
    # Get containers from the ContainerManager
    Logger.info("Fetching containers from ContainerManager...")

    case LoadBalancer.ContainerManager.get_containers() do
      containers when is_list(containers) ->
        Logger.info("Got containers list with #{length(containers)} containers")
        # Convert the container structs to a map format for the UI
        Enum.map(containers, fn container ->
          %{
            "name" => container.name,
            "status" => Atom.to_string(container.status),
            "health" => case container.status do
              :healthy -> "healthy"
              :unhealthy -> "unhealthy"
              :starting -> "starting"
              :stopped -> "stopped"
              :running -> "running"
              :paused -> "paused"
              :exited -> "exited"
              :created -> "created"
              _ -> "unknown"
            end,
            "ports" => container.endpoint,
            "connection_count" => container.connection_count || 0
          }
        end)
      other ->
        Logger.warn("Unexpected containers format: #{inspect(other)}")
        []
    end
  end
end
