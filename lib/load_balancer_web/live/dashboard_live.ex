defmodule LoadBalancerWeb.DashboardLive do
  use LoadBalancerWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Schedule periodic updates
      :timer.send_interval(5000, self(), :update_data)
      # Get initial data
      send(self(), :update_data)
    end

    {:ok, assign(socket,
      page_title: "Dashboard",
      domains: [],
      containers: [],
      metrics: %{},
      loading: true
    )}
  end

  def handle_info(:update_data, socket) do
    # Fetch data from API endpoints
    domains = fetch_domains()
    containers = fetch_containers()
    metrics = fetch_metrics()

    {:noreply, assign(socket,
      domains: domains,
      containers: containers,
      metrics: metrics,
      loading: false
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Hero Section -->
      <div class="text-center space-y-4">
        <h1 class="text-5xl font-bold bg-gradient-to-r from-white via-blue-200 to-purple-200 bg-clip-text text-transparent">
          Load Balancer Dashboard
        </h1>
        <p class="text-xl text-gray-300 max-w-2xl mx-auto">
          Monitor and manage your distributed infrastructure with real-time insights and powerful controls
        </p>
      </div>

      <!-- Loading State -->
      <%= if @loading do %>
        <div class="text-center py-12">
          <div class="inline-flex items-center px-4 py-2 font-semibold leading-6 text-white shadow rounded-md">
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Loading dashboard data...
          </div>
        </div>
      <% else %>
        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <!-- Active Domains Card -->
          <div class="group relative">
            <div class="absolute -inset-0.5 bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/20 transition-all duration-300 hover:scale-105">
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                  <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl flex items-center justify-center shadow-lg">
                    <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
                    </svg>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-gray-300 uppercase tracking-wider">Active Domains</dt>
                    <dd class="text-4xl font-bold text-white"><%= length(@domains) %></dd>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-2xl text-green-400">●</div>
                  <div class="text-xs text-gray-400">Online</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Healthy Containers Card -->
          <div class="group relative">
            <div class="absolute -inset-0.5 bg-gradient-to-r from-green-600 to-emerald-600 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/20 transition-all duration-300 hover:scale-105">
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                  <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-2xl flex items-center justify-center shadow-lg">
                    <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-gray-300 uppercase tracking-wider">Healthy Containers</dt>
                    <dd class="text-4xl font-bold text-white">
                      <%= @containers |> Enum.filter(&(&1.health == "healthy")) |> length() %>
                    </dd>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-2xl text-green-400">●</div>
                  <div class="text-xs text-gray-400">Running</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Total Containers Card -->
          <div class="group relative">
            <div class="absolute -inset-0.5 bg-gradient-to-r from-purple-600 to-pink-600 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/20 transition-all duration-300 hover:scale-105">
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                  <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg">
                    <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                    </svg>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-gray-300 uppercase tracking-wider">Total Containers</dt>
                    <dd class="text-4xl font-bold text-white"><%= length(@containers) %></dd>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-2xl text-blue-400">●</div>
                  <div class="text-xs text-gray-400">Active</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Domain Status -->
        <div class="group relative">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>
          <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/20 transition-all duration-300">
            <h3 class="text-2xl font-bold text-white mb-6">Domain Status</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <%= for domain <- @domains do %>
                <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-2">
                    <span class="font-semibold text-white"><%= domain.domain %></span>
                    <span class={[
                      "px-2 py-1 rounded-full text-xs font-medium",
                      if(domain.status == "active", do: "bg-green-500/20 text-green-400", else: "bg-red-500/20 text-red-400")
                    ]}>
                      <%= domain.status %>
                    </span>
                  </div>
                  <div class="text-sm text-gray-300">
                    <div>Strategy: <%= domain.strategy %></div>
                    <div>Health Check: <%= domain.health_check %></div>
                    <div>Containers: <%= Enum.join(domain.containers, ", ") %></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Container Status -->
        <div class="group relative">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-emerald-600 to-teal-600 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>
          <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/20 transition-all duration-300">
            <h3 class="text-2xl font-bold text-white mb-6">Container Status</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <%= for container <- @containers do %>
                <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-2">
                    <span class="font-semibold text-white"><%= container.name %></span>
                    <span class={[
                      "px-2 py-1 rounded-full text-xs font-medium",
                      case container.health do
                        "healthy" -> "bg-green-500/20 text-green-400"
                        "unhealthy" -> "bg-red-500/20 text-red-400"
                        _ -> "bg-yellow-500/20 text-yellow-400"
                      end
                    ]}>
                      <%= container.health %>
                    </span>
                  </div>
                  <div class="text-sm text-gray-300">
                    <div>Status: <%= container.status %></div>
                    <div>Ports: <%= container.ports %></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300">
            <h3 class="text-lg font-semibold text-white mb-4">Quick Actions</h3>
            <div class="space-y-3">
              <button class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 hover:scale-105 hover:shadow-lg">
                Add New Domain
              </button>
              <button class="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 hover:scale-105 hover:shadow-lg">
                Deploy Container
              </button>
            </div>
          </div>

          <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300">
            <h3 class="text-lg font-semibold text-white mb-4">Recent Activity</h3>
            <div class="space-y-3 text-gray-300">
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-green-400 rounded-full"></div>
                <span class="text-sm">System startup completed</span>
              </div>
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-blue-400 rounded-full"></div>
                <span class="text-sm">Load balancer initialized</span>
              </div>
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-purple-400 rounded-full"></div>
                <span class="text-sm">Monitoring services active</span>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Private helper functions

  defp fetch_domains() do
    case HTTPoison.get("http://localhost:4000/api/routes") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"routes" => routes}} -> routes
          _ -> []
        end
      _ -> []
    end
  end

  defp fetch_containers() do
    case HTTPoison.get("http://localhost:4000/api/containers") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"containers" => containers}} -> containers
          _ -> []
        end
      _ -> []
    end
  end

  defp fetch_metrics() do
    case HTTPoison.get("http://localhost:4000/api/metrics") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, metrics} -> metrics
          _ -> %{}
        end
      _ -> %{}
    end
  end
end
