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
        <h1 class="text-5xl font-bold text-slate-900">
          Load Balancer Dashboard
        </h1>
        <p class="text-xl text-slate-600 max-w-2xl mx-auto">
          Monitor and manage your distributed infrastructure with real-time insights and powerful controls
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
            Loading dashboard data...
          </div>
        </div>
      <% else %>
        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <!-- Active Domains Card -->
          <div class="enterprise-card p-8 hover:scale-[1.02] transition-all duration-300">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-md">
                  <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
                  </svg>
                </div>
                <div>
                  <dt class="text-sm font-medium text-slate-600 uppercase tracking-wider">Active Domains</dt>
                  <dd class="text-4xl font-bold text-slate-900"><%= length(@domains) %></dd>
                </div>
              </div>
              <div class="text-right">
                <div class="text-2xl text-green-500">●</div>
                <div class="text-xs text-slate-500">Online</div>
              </div>
            </div>
          </div>

          <!-- Healthy Containers Card -->
          <div class="enterprise-card p-8 hover:scale-[1.02] transition-all duration-300">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center shadow-md">
                  <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </div>
                <div>
                  <dt class="text-sm font-medium text-slate-600 uppercase tracking-wider">Healthy Containers</dt>
                  <dd class="text-4xl font-bold text-slate-900">
                    <%= @containers |> Enum.filter(&(&1.health == "healthy")) |> length() %>
                  </dd>
                </div>
              </div>
              <div class="text-right">
                <div class="text-2xl text-green-500">●</div>
                <div class="text-xs text-slate-500">Running</div>
              </div>
            </div>
          </div>

          <!-- Total Containers Card -->
          <div class="enterprise-card p-8 hover:scale-[1.02] transition-all duration-300">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <div class="w-16 h-16 bg-gradient-to-br from-slate-500 to-slate-600 rounded-xl flex items-center justify-center shadow-md">
                  <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                  </svg>
                </div>
                <div>
                  <dt class="text-sm font-medium text-slate-600 uppercase tracking-wider">Total Containers</dt>
                  <dd class="text-4xl font-bold text-slate-900"><%= length(@containers) %></dd>
                </div>
              </div>
              <div class="text-right">
                <div class="text-2xl text-blue-500">●</div>
                <div class="text-xs text-slate-500">Active</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Domain Status -->
        <div class="enterprise-card p-8">
          <h3 class="text-2xl font-bold text-slate-900 mb-6">Domain Status</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <%= for domain <- @domains do %>
              <div class="bg-slate-50 border border-slate-200 rounded-lg p-4 hover:bg-slate-100 transition-colors duration-200">
                <div class="flex items-center justify-between mb-2">
                  <span class="font-semibold text-slate-900"><%= domain.domain %></span>
                  <span class={[
                    "status-indicator",
                    if(domain.status == "active", do: "status-healthy", else: "status-error")
                  ]}>
                    <%= domain.status %>
                  </span>
                </div>
                <div class="text-sm text-slate-600">
                  <div>Strategy: <%= domain.strategy %></div>
                  <div>Health Check: <%= domain.health_check %></div>
                  <div>Containers: <%= Enum.join(domain.containers, ", ") %></div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Container Status -->
        <div class="enterprise-card p-8">
          <h3 class="text-2xl font-bold text-slate-900 mb-6">Container Status</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <%= for container <- @containers do %>
              <div class="bg-slate-50 border border-slate-200 rounded-lg p-4 hover:bg-slate-100 transition-colors duration-200">
                <div class="flex items-center justify-between mb-2">
                  <span class="font-semibold text-slate-900"><%= container.name %></span>
                  <span class={[
                    "status-indicator",
                    case container.health do
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
                    <%= container.health %>
                  </span>
                </div>
                <div class="text-sm text-slate-600">
                  <div>Status: <%= container.status %></div>
                  <div>Ports: <%= container.ports %></div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="enterprise-card p-6">
            <h3 class="text-lg font-semibold text-slate-900 mb-4">Quick Actions</h3>
            <div class="space-y-3">
              <button class="enterprise-button w-full">
                Add New Domain
              </button>
              <button class="enterprise-button-secondary w-full">
                Deploy Container
              </button>
            </div>
          </div>

          <div class="enterprise-card p-6">
            <h3 class="text-lg font-semibold text-slate-900 mb-4">Recent Activity</h3>
            <div class="space-y-3 text-slate-600">
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-green-500 rounded-full"></div>
                <span class="text-sm">System startup completed</span>
              </div>
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-blue-500 rounded-full"></div>
                <span class="text-sm">Load balancer initialized</span>
              </div>
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-slate-500 rounded-full"></div>
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
    # Call the domain store directly instead of making HTTP requests
    LoadBalancer.DomainStore.get_all_domains()
  end

  defp fetch_containers() do
    # Get containers directly from ContainerManager
    case LoadBalancer.ContainerManager.get_containers() do
      containers when is_list(containers) ->
        Enum.map(containers, fn container ->
          %{
            name: container.name,
            status: Atom.to_string(container.status),
            ports: container.endpoint,
            health: case container.status do
              :healthy -> "healthy"
              :running -> "running"
              :starting -> "starting"
              :unhealthy -> "unhealthy"
              :stopped -> "stopped"
              :exited -> "exited"
              :paused -> "paused"
              _ -> "unknown"
            end
          }
        end)
      _ ->
        []
    end
  end

  defp fetch_metrics() do
    # For now, return default metrics since we don't have a metrics store yet
    # TODO: Implement metrics collection and storage
    %{
      response_time: 0,
      error_rate: 0,
      throughput: 0,
      active_connections: 0,
      containers: %{},
      domains: %{}
    }
  end
end
