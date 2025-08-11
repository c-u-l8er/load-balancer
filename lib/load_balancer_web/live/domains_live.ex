defmodule LoadBalancerWeb.DomainsLive do
  use LoadBalancerWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Schedule periodic updates
      :timer.send_interval(5000, self(), :update_domains)
      # Get initial data
      send(self(), :update_domains)
    end

    {:ok, assign(socket,
      page_title: "Domains",
      domains: [],
      loading: true
    )}
  end

  def handle_info(:update_domains, socket) do
    domains = fetch_domains()
    {:noreply, assign(socket, domains: domains, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Hero Section -->
      <div class="text-center space-y-4">
        <h1 class="text-5xl font-bold bg-gradient-to-r from-white via-purple-200 to-pink-200 bg-clip-text text-transparent">
          Domain Management
        </h1>
        <p class="text-xl text-gray-300 max-w-2xl mx-auto">
          Configure and manage your load balancer routes and domain mappings
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
            Loading domain data...
          </div>
        </div>
      <% else %>
        <!-- Domain Stats -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div class="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-white"><%= length(@domains) %></div>
            <div class="text-sm text-gray-300">Total Domains</div>
          </div>

          <div class="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-white">
              <%= @domains |> Enum.filter(&(&1.status == "active")) |> length() %>
            </div>
            <div class="text-sm text-gray-300">Active</div>
          </div>

          <div class="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-white">
              <%= @domains |> Enum.count(&(&1.strategy == "round_robin")) %>
            </div>
            <div class="text-sm text-gray-300">Round Robin</div>
          </div>

          <div class="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-yellow-500 to-orange-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-white">
              <%= @domains |> Enum.map(&length(&1.containers)) |> Enum.sum() %>
            </div>
            <div class="text-sm text-gray-300">Total Backends</div>
          </div>
        </div>

        <!-- Main Domain Section -->
        <div class="group relative">
          <div class="absolute -inset-0.5 bg-gradient-to-r from-purple-600 to-pink-600 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200"></div>
          <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 hover:bg-white/20 transition-all duration-300">
            <div class="flex items-center justify-between mb-6">
              <div class="flex items-center space-x-4">
                <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
                  </svg>
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-white">Domain Routes</h3>
                  <p class="text-gray-300">Manage your load balancer domain configurations</p>
                </div>
              </div>
              <button class="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-medium py-3 px-6 rounded-xl transition-all duration-200 hover:scale-105 hover:shadow-lg">
                Add Domain
              </button>
            </div>

            <!-- Domain List -->
            <%= if Enum.empty?(@domains) do %>
              <!-- Empty State -->
              <div class="text-center py-12">
                <div class="w-24 h-24 bg-white/5 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
                  </svg>
                </div>
                <h3 class="text-lg font-medium text-gray-300 mb-2">No domains configured</h3>
                <p class="text-gray-400">Start by adding your first domain route to the load balancer.</p>
              </div>
            <% else %>
              <!-- Domain Grid -->
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <%= for domain <- @domains do %>
                  <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300">
                    <div class="flex items-start justify-between mb-4">
                      <div class="flex items-center space-x-3">
                        <div class={[
                          "w-3 h-3 rounded-full",
                          if(domain.status == "active", do: "bg-green-400", else: "bg-red-400")
                        ]}></div>
                        <h4 class="text-lg font-semibold text-white"><%= domain.domain %></h4>
                      </div>
                      <div class="flex space-x-2">
                        <button class="p-2 text-gray-400 hover:text-white transition-colors">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
                          </svg>
                        </button>
                        <button class="p-2 text-gray-400 hover:text-white transition-colors">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                          </svg>
                        </button>
                      </div>
                    </div>

                    <div class="space-y-3">
                      <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-400">Status</span>
                        <span class={[
                          "px-2 py-1 rounded-full text-xs font-medium",
                          if(domain.status == "active", do: "bg-green-500/20 text-green-400", else: "bg-red-500/20 text-red-400")
                        ]}>
                          <%= domain.status %>
                        </span>
                      </div>

                      <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-400">Strategy</span>
                        <span class="text-sm text-white font-medium"><%= domain.strategy %></span>
                      </div>

                      <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-400">Health Check</span>
                        <span class="text-sm text-white font-mono"><%= domain.health_check %></span>
                      </div>

                      <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-400">Backends</span>
                        <span class="text-sm text-white"><%= length(domain.containers) %></span>
                      </div>
                    </div>

                    <div class="mt-4 pt-4 border-t border-white/10">
                      <div class="text-sm text-gray-300 mb-3">
                        <span class="font-medium">Backend Containers:</span>
                      </div>
                      <div class="space-y-1">
                        <%= for container <- domain.containers do %>
                          <div class="text-xs bg-white/5 rounded px-2 py-1 text-white font-mono">
                            <%= container %>
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <div class="mt-4 pt-4 border-t border-white/10">
                      <div class="flex space-x-2">
                        <button class="flex-1 bg-white/10 hover:bg-white/20 text-white text-sm py-2 px-3 rounded-lg transition-colors">
                          Test Route
                        </button>
                        <button class="flex-1 bg-white/10 hover:bg-white/20 text-white text-sm py-2 px-3 rounded-lg transition-colors">
                          View Logs
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
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
                Import Configuration
              </button>
            </div>
          </div>

          <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6 hover:bg-white/10 transition-all duration-300">
            <h3 class="text-lg font-semibold text-white mb-4">Domain Templates</h3>
            <div class="space-y-3 text-gray-300">
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-blue-400 rounded-full"></div>
                <span class="text-sm">Web Application</span>
              </div>
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-green-400 rounded-full"></div>
                <span class="text-sm">API Service</span>
              </div>
              <div class="flex items-center space-x-3">
                <div class="w-2 h-2 bg-purple-400 rounded-full"></div>
                <span class="text-sm">Database Cluster</span>
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
          {:ok, %{"routes" => routes}} ->
            Enum.map(routes, fn route ->
              %{
                domain: route["domain"],
                containers: route["containers"],
                strategy: route["strategy"],
                health_check: route["health_check"],
                status: route["status"]
              }
            end)
          _ -> []
        end
      _ -> []
    end
  end
end
