defmodule LoadBalancerWeb.MetricsLive do
  use LoadBalancerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Metrics", metrics: [])}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Hero Section -->
      <div class="text-center space-y-4">
        <h1 class="text-5xl font-bold text-slate-900">
          Performance Metrics
        </h1>
        <p class="text-xl text-slate-600 max-w-2xl mx-auto">
          Real-time insights into your load balancer performance and system health
        </p>
      </div>

      <!-- Key Metrics Grid -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="enterprise-card p-6 text-center">
          <div class="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center mx-auto mb-4">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
          </div>
          <div class="text-2xl font-bold text-slate-900">0</div>
          <div class="text-sm text-slate-600">Requests/sec</div>
        </div>

        <div class="enterprise-card p-6 text-center">
          <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
          </div>
          <div class="text-2xl font-bold text-slate-900">0ms</div>
          <div class="text-sm text-slate-600">Avg Response</div>
        </div>

        <div class="enterprise-card p-6 text-center">
          <div class="w-12 h-12 bg-gradient-to-br from-slate-500 to-slate-600 rounded-xl flex items-center justify-center mx-auto mb-4">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
          </div>
          <div class="text-2xl font-bold text-slate-900">0%</div>
          <div class="text-sm text-slate-600">CPU Usage</div>
        </div>

        <div class="enterprise-card p-6 text-center">
          <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"></path>
            </svg>
          </div>
          <div class="text-2xl font-bold text-slate-900">0MB</div>
          <div class="text-sm text-slate-600">Memory</div>
        </div>
      </div>

      <!-- Main Metrics Section -->
      <div class="enterprise-card p-8">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center space-x-4">
            <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-md">
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
            </div>
            <div>
              <h3 class="text-2xl font-bold text-slate-900">Performance Analytics</h3>
              <p class="text-slate-600">Monitor system performance and traffic patterns</p>
            </div>
          </div>
          <div class="flex space-x-3">
            <button class="enterprise-button">
              Real-time
            </button>
            <button class="enterprise-button-secondary">
              Historical
            </button>
          </div>
        </div>

        <!-- Empty State -->
        <div class="text-center py-12">
          <div class="w-24 h-24 bg-gradient-to-br from-slate-400 to-slate-500 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
          </div>
          <h4 class="text-xl font-semibold text-slate-900 mb-2">No metrics available yet</h4>
          <p class="text-slate-500 mb-6">Start monitoring your load balancer to see performance data</p>
          <div class="flex justify-center space-x-4">
            <button class="enterprise-button">
              Start Monitoring
            </button>
            <button class="enterprise-button-secondary">
              Configure Alerts
            </button>
          </div>
        </div>
      </div>

      <!-- Metric Categories -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="footer-component p-6 hover:bg-slate-100/95 transition-all duration-300 group">
          <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-200">
            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
          </div>
          <h4 class="text-lg font-semibold footer-text mb-2">Traffic Metrics</h4>
          <p class="text-slate-600 text-sm mb-4">Request rates, bandwidth usage, and traffic patterns</p>
          <button class="w-full enterprise-button py-2 px-4">
            View Details
          </button>
        </div>

        <div class="footer-component p-6 hover:bg-slate-100/95 transition-all duration-300 group">
          <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-200">
            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
          </div>
          <h4 class="text-lg font-semibold footer-text mb-2">Performance</h4>
          <p class="text-slate-600 text-sm mb-4">Response times, latency, and throughput metrics</p>
          <button class="w-full enterprise-button py-2 px-4">
            View Details
          </button>
        </div>

        <div class="footer-component p-6 hover:bg-slate-100/95 transition-all duration-300 group">
          <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-200">
            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
            </svg>
          </div>
          <h4 class="text-lg font-semibold footer-text mb-2">System Health</h4>
          <p class="text-slate-600 text-sm mb-4">CPU, memory, and resource utilization</p>
          <button class="w-full enterprise-button py-2 px-4">
            View Details
          </button>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="footer-component p-6">
        <h3 class="text-lg font-semibold footer-text mb-4">Quick Actions</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <button class="enterprise-button py-3 px-4">
            <div class="flex items-center space-x-3">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
              </svg>
              <span>Export Data</span>
            </div>
          </button>
          <br />
          <button class="enterprise-button-secondary py-3 px-4">
            <div class="flex items-center space-x-3">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM4 19h6v-2H4v2zM4 15h6v-2H4v2zM4 11h6V9H4v2zM4 7h6V5H4v2zM4 3h6V1H4v2z"></path>
              </svg>
              <span>Set Alerts</span>
            </div>
          </button>
        </div>
      </div>
    </div>
    """
  end
end
