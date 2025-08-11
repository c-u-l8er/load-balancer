defmodule LoadBalancerWeb.DomainsLive do
  use LoadBalancerWeb, :live_view
  require Logger

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
      loading: true,
      show_add_form: false,
      show_edit_form: false,
      editing_domain: nil,
      form_data: %{
        domain: "",
        containers: "",
        strategy: "round_robin",
        health_check: "/",
        status: "active"
      }
    )}
  end

  def handle_info(:update_domains, socket) do
    Logger.info("Received :update_domains message")
    domains = fetch_domains()
    Logger.info("Fetched domains: #{inspect(domains)}")
    {:noreply, assign(socket, domains: domains, loading: false)}
  end

  # Event handlers for domain management
  def handle_event("show_add_form", _params, socket) do
    {:noreply, assign(socket, show_add_form: true, show_edit_form: false)}
  end

  def handle_event("hide_add_form", _params, socket) do
    {:noreply, assign(socket, show_add_form: false, form_data: %{
      domain: "",
      containers: "",
      strategy: "round_robin",
      health_check: "/",
      status: "active"
    })}
  end

  def handle_event("show_edit_form", %{"domain" => domain_name}, socket) do
    domain = Enum.find(socket.assigns.domains, &(&1.domain == domain_name))
    if domain do
      form_data = %{
        domain: domain.domain,
        containers: Enum.join(domain.containers, ","),
        strategy: domain.strategy,
        health_check: domain.health_check,
        status: domain.status
      }
      {:noreply, assign(socket,
        show_edit_form: true,
        show_add_form: false,
        editing_domain: domain,
        form_data: form_data
      )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("hide_edit_form", _params, socket) do
    {:noreply, assign(socket, show_edit_form: false, editing_domain: nil)}
  end



  def handle_event("add_domain", params, socket) do
    # Extract form data from params
    form_data = %{
      "domain" => params["form_data"]["domain"],
      "containers" => params["form_data"]["containers"],
      "strategy" => params["form_data"]["strategy"],
      "health_check" => params["form_data"]["health_check"],
      "status" => params["form_data"]["status"]
    }

    # Basic validation
    cond do
      form_data["domain"] == "" ->
        {:noreply, put_flash(socket, :error, "Domain name is required")}

      form_data["containers"] == "" ->
        {:noreply, put_flash(socket, :error, "At least one container is required")}

      form_data["health_check"] == "" ->
        {:noreply, put_flash(socket, :error, "Health check path is required")}

      true ->
                         case create_domain(form_data) do
                   {:ok, _} ->
                     # Auto-save domains to disk
                     LoadBalancer.DomainPersistence.save_domains()
                     # Refresh domains from store
                     domains = LoadBalancer.DomainStore.get_all_domains()
                     {:noreply, assign(socket,
                       domains: domains,
                       show_add_form: false,
                       form_data: %{
                         domain: "",
                         containers: "",
                         strategy: "round_robin",
                         health_check: "/",
                         status: "active"
                       }
                     ) |> put_flash(:info, "Domain created successfully")}
                   {:error, message} ->
                     {:noreply, put_flash(socket, :error, "Failed to create domain: #{message}")}
                 end
    end
  end

  def handle_event("update_domain", params, socket) do
    # Extract form data from params
    form_data = %{
      "domain" => params["form_data"]["domain"],
      "containers" => params["form_data"]["containers"],
      "strategy" => params["form_data"]["strategy"],
      "health_check" => params["form_data"]["health_check"],
      "status" => params["form_data"]["status"]
    }

    # Basic validation
    cond do
      form_data["domain"] == "" ->
        {:noreply, put_flash(socket, :error, "Domain name is required")}

      form_data["containers"] == "" ->
        {:noreply, put_flash(socket, :error, "At least one container is required")}

      form_data["health_check"] == "" ->
        {:noreply, put_flash(socket, :error, "Health check path is required")}

      true ->
                         case update_domain(socket.assigns.editing_domain.domain, form_data) do
                   {:ok, _} ->
                     # Auto-save domains to disk
                     LoadBalancer.DomainPersistence.save_domains()
                     # Refresh domains from store
                     domains = LoadBalancer.DomainStore.get_all_domains()
                     {:noreply, assign(socket,
                       domains: domains,
                       show_edit_form: false,
                       editing_domain: nil
                     ) |> put_flash(:info, "Domain updated successfully")}
                   {:error, message} ->
                     {:noreply, put_flash(socket, :error, "Failed to update domain: #{message}")}
                 end
    end
  end

  def handle_event("delete_domain", %{"domain" => domain_name}, socket) do
    case delete_domain(domain_name) do
      {:ok, _} ->
        # Auto-save domains to disk
        LoadBalancer.DomainPersistence.save_domains()
        # Refresh domains from store
        domains = LoadBalancer.DomainStore.get_all_domains()
        {:noreply, assign(socket, domains: domains) |> put_flash(:info, "Domain deleted successfully")}
      {:error, message} ->
        {:noreply, put_flash(socket, :error, "Failed to delete domain: #{message}")}
    end
  end

  def handle_event("save_domains", _params, socket) do
    case LoadBalancer.DomainPersistence.save_domains() do
      {:ok, count} ->
        {:noreply, put_flash(socket, :info, "Successfully saved #{count} domains to disk")}
      {:error, message} ->
        {:noreply, put_flash(socket, :error, "Failed to save domains: #{message}")}
    end
  end

  def handle_event("reload_domains", _params, socket) do
    case LoadBalancer.DomainPersistence.load_domains() do
      {:ok, count} ->
        # Refresh domains from store after reloading from disk
        domains = LoadBalancer.DomainStore.get_all_domains()
        {:noreply, assign(socket, domains: domains) |> put_flash(:info, "Successfully reloaded #{count} domains from disk")}
      {:error, message} ->
        {:noreply, put_flash(socket, :error, "Failed to reload domains: #{message}")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Hero Section -->
      <div class="text-center space-y-4">
        <h1 class="text-5xl font-bold text-slate-900">
          Domain Management
        </h1>
        <p class="text-xl text-slate-600 max-w-2xl mx-auto">
          Configure and manage your load balancer routes and domain mappings
        </p>
      </div>

      <!-- Flash Messages -->
      <%= if live_flash(@flash, :info) do %>
        <div class="bg-green-100 border border-green-300 rounded-lg p-4 text-green-800">
          <%= live_flash(@flash, :info) %>
        </div>
      <% end %>

      <%= if live_flash(@flash, :error) do %>
        <div class="bg-red-100 border border-red-300 rounded-lg p-4 text-red-800">
          <%= live_flash(@flash, :error) %>
        </div>
      <% end %>

      <!-- Loading State -->
      <%= if @loading do %>
        <div class="text-center py-12">
          <div class="inline-flex items-center px-4 py-2 font-semibold leading-6 text-slate-700 bg-slate-100 rounded-lg">
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-slate-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Loading domain data...
          </div>
        </div>
      <% else %>
        <div class="space-y-8">
          <!-- Domain Stats -->
          <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900"><%= length(@domains) %></div>
            <div class="text-sm text-slate-600">Total Domains</div>
          </div>

          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900">
              <%= @domains |> Enum.filter(&(&1.status == "active")) |> length() %>
            </div>
            <div class="text-sm text-slate-600">Active</div>
          </div>

          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-slate-500 to-slate-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900">
              <%= @domains |> Enum.count(&(&1.strategy == "round_robin")) %>
            </div>
            <div class="text-sm text-slate-600">Round Robin</div>
          </div>

          <div class="enterprise-card p-6 text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
              </svg>
            </div>
            <div class="text-2xl font-bold text-slate-900">
              <%= @domains |> Enum.map(&length(&1.containers)) |> Enum.sum() %>
            </div>
            <div class="text-sm text-slate-600">Total Backends</div>
          </div>
        </div>

        <!-- Main Domain Section -->
        <div class="enterprise-card p-8">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center space-x-4">
              <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-md">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
                </svg>
              </div>
              <div>
                <h3 class="text-2xl font-bold text-slate-900">Domain Routes</h3>
                <p class="text-slate-600">Manage your load balancer domain configurations</p>
              </div>
            </div>
            <div class="flex space-x-3">
                              <button phx-click="save_domains" class="enterprise-button">
                  Save to Disk
                </button>
                <button phx-click="reload_domains" class="enterprise-button-secondary">
                  Reload from Disk
                </button>
                <button phx-click="show_add_form" class="enterprise-button">
                  Add Domain
                </button>
              </div>
            </div>

            <!-- Domain List -->
            <div class="space-y-6">
              <%= if Enum.empty?(@domains) do %>
              <!-- Empty State -->
              <div class="text-center py-12">
                <div class="w-24 h-24 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg class="w-12 h-12 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9m0-9c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9"></path>
                  </svg>
                </div>
                <h3 class="text-lg font-medium text-slate-900 mb-2">No domains configured</h3>
                <p class="text-slate-600">Start by adding your first domain route to the load balancer.</p>
              </div>
            <% else %>
              <!-- Domain Grid -->
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <%= for domain <- @domains do %>
                  <div class="bg-slate-50 border border-slate-200 rounded-xl p-6 hover:bg-slate-100 transition-all duration-300">
                    <div class="flex items-start justify-between mb-4">
                      <div class="flex items-center space-x-3">
                        <div class={[
                          "w-3 h-3 rounded-full",
                          if(domain.status == "active", do: "bg-green-500", else: "bg-red-500")
                        ]}></div>
                        <h4 class="text-lg font-semibold text-slate-900"><%= domain.domain %></h4>
                      </div>
                      <div class="flex space-x-2">
                        <button phx-click="show_edit_form" phx-value-domain={domain.domain} class="p-2 text-slate-400 hover:text-slate-600 transition-colors" title="Edit Domain">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
                          </svg>
                        </button>
                        <button phx-click="delete_domain" phx-value-domain={domain.domain} class="p-2 text-slate-400 hover:text-red-500 transition-colors" title="Delete Domain">
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
                          if(domain.status == "active", do: "status-healthy", else: "status-error")
                        ]}>
                          <%= domain.status %>
                        </span>
                      </div>

                      <div class="flex items-center justify-between">
                        <span class="text-sm text-slate-600">Strategy</span>
                        <span class="text-sm text-slate-900 font-medium"><%= domain.strategy %></span>
                      </div>

                      <div class="flex items-center justify-between">
                        <span class="text-sm text-slate-600">Health Check</span>
                        <span class="text-sm text-slate-900 font-mono"><%= domain.health_check %></span>
                      </div>

                      <div class="flex items-center justify-between">
                        <span class="text-sm text-slate-600">Backends</span>
                        <span class="text-sm text-slate-900"><%= length(domain.containers) %></span>
                      </div>
                    </div>

                    <div class="mt-4 pt-4 border-t border-slate-200">
                      <div class="text-sm text-slate-600 mb-3">
                        <span class="font-medium">Backend Containers:</span>
                      </div>
                      <div class="space-y-1">
                        <%= for container <- domain.containers do %>
                          <div class="text-xs bg-slate-100 rounded px-2 py-1 text-slate-700 font-mono">
                            <%= container %>
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <div class="mt-4 pt-4 border-t border-slate-200">
                      <div class="flex space-x-2">
                        <button class="flex-1 enterprise-button-secondary text-sm py-2 px-3">
                          Test Route
                        </button>
                        <button class="flex-1 enterprise-button-secondary text-sm py-2 px-3">
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
        </div>

        <!-- Add Domain Form -->
        <%= if @show_add_form do %>
          <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <div class="enterprise-card p-8 max-w-md w-full mx-4">
              <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center">
                    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                    </svg>
                  </div>
                  <h3 class="text-2xl font-bold enterprise-text">Add New Domain</h3>
                </div>
                <button phx-click="hide_add_form" class="text-slate-400 hover:text-slate-600 transition-colors">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                </button>
              </div>

              <form phx-submit="add_domain" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Domain Name</label>
                  <input type="text" name="form_data[domain]" value={@form_data.domain} required
                         class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                         placeholder="example.com" />
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Containers (comma-separated)</label>
                  <input type="text" name="form_data[containers]" value={@form_data.containers} required
                         class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                         placeholder="web1:8080,web2:8080" />
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Load Balancing Strategy</label>
                  <select name="form_data[strategy]" value={@form_data.strategy}
                          class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="round_robin">Round Robin</option>
                    <option value="least_connections">Least Connections</option>
                    <option value="ip_hash">IP Hash</option>
                    <option value="weighted_round_robin">Weighted Round Robin</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Health Check Path</label>
                  <input type="text" name="form_data[health_check]" value={@form_data.health_check} required
                         class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                         placeholder="/health" />
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Status</label>
                  <select name="form_data[status]" value={@form_data.status}
                          class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>

                <div class="flex space-x-3 pt-4">
                  <button type="submit" class="flex-1 enterprise-button py-2 px-4">
                    Add Domain
                  </button>
                  <button type="button" phx-click="hide_add_form" class="flex-1 enterprise-button-secondary py-2 px-4">
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>

        <!-- Edit Domain Form -->
        <%= if @show_edit_form do %>
          <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <div class="enterprise-card p-8 max-w-md w-full mx-4">
              <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center">
                    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.045a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
                    </svg>
                  </div>
                  <h3 class="text-2xl font-bold enterprise-text">Edit Domain: <%= @editing_domain.domain %></h3>
                </div>
                <button phx-click="hide_edit_form" class="text-slate-400 hover:text-slate-600 transition-colors">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                </button>
              </div>

              <form phx-submit="update_domain" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Domain Name</label>
                  <input type="text" name="form_data[domain]" value={@form_data.domain} required
                         class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                         placeholder="example.com" />
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Containers (comma-separated)</label>
                  <input type="text" name="form_data[containers]" value={@form_data.containers} required
                         class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                         placeholder="web1:8080,web2:8080" />
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Load Balancing Strategy</label>
                  <select name="form_data[strategy]" value={@form_data.strategy}
                          class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="round_robin">Round Robin</option>
                    <option value="least_connections">Least Connections</option>
                    <option value="ip_hash">IP Hash</option>
                    <option value="weighted_round_robin">Weighted Round Robin</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Health Check Path</label>
                  <input type="text" name="form_data[health_check]" value={@form_data.health_check} required
                         class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                         placeholder="/health" />
                </div>

                <div>
                  <label class="block text-sm font-medium enterprise-text mb-2">Status</label>
                  <select name="form_data[status]" value={@form_data.status}
                          class="w-full bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 enterprise-text focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>

                <div class="flex space-x-3 pt-4">
                  <button type="submit" class="flex-1 enterprise-button py-2 px-4">
                    Update Domain
                  </button>
                  <button type="button" phx-click="hide_edit_form" class="flex-1 enterprise-button-secondary py-2 px-4">
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>

        <!-- Quick Actions -->
        <div class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="footer-component p-6 hover:bg-slate-100/95 transition-all duration-300">
            <h3 class="text-lg font-semibold footer-text mb-4">Quick Actions</h3>
            <div class="space-y-3">
              <button class="w-full enterprise-button py-3 px-4">
                Add New Domain
              </button>
              <button class="w-full enterprise-button-secondary py-3 px-4">
                Import Configuration
              </button>
            </div>
          </div>

          <div class="footer-component p-6 hover:bg-slate-100/95 transition-all duration-300">
            <h3 class="text-lg font-semibold footer-text mb-4">Domain Templates</h3>
            <div class="space-y-3 text-slate-600">
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
        </div>
      <% end %>
    </div>
    """
  end

  # Private helper functions

  defp fetch_domains() do
    # Call the domain store directly instead of making HTTP requests
    Logger.info("Fetching domains directly from DomainStore")
    domains = LoadBalancer.DomainStore.get_all_domains()
    Logger.info("Retrieved #{length(domains)} domains from store: #{inspect(domains)}")
    domains
  end

  defp create_domain(form_data) do
    Logger.info("Creating domain with form data: #{inspect(form_data)}")

    containers = form_data["containers"]
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))

    domain_data = %{
      domain: form_data["domain"],
      containers: containers,
      strategy: form_data["strategy"],
      health_check: form_data["health_check"],
      status: form_data["status"]
    }

    Logger.info("Processed domain data: #{inspect(domain_data)}")

    # Call the domain store directly
    case LoadBalancer.DomainStore.add_domain(domain_data) do
      {:ok, domain} ->
        Logger.info("Domain created successfully: #{inspect(domain)}")
        {:ok, "Domain created successfully"}
      {:error, reason} ->
        Logger.error("Failed to create domain: #{reason}")
        {:error, reason}
    end
  end

  defp update_domain(domain_name, form_data) do
    containers = form_data["containers"]
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))

    domain_data = %{
      domain: form_data["domain"],
      containers: containers,
      strategy: form_data["strategy"],
      health_check: form_data["health_check"],
      status: form_data["status"]
    }

    # Call the domain store directly
    case LoadBalancer.DomainStore.update_domain(domain_name, domain_data) do
      {:ok, domain} -> {:ok, "Domain updated successfully"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp delete_domain(domain_name) do
    # Call the domain store directly
    case LoadBalancer.DomainStore.delete_domain(domain_name) do
      {:ok, _} -> {:ok, "Domain deleted successfully"}
      {:error, reason} -> {:error, reason}
    end
  end
end
