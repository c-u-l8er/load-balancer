defmodule LoadBalancerWeb.Router do
  use LoadBalancerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LoadBalancerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LoadBalancerWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/dashboard", DashboardLive
    live "/domains", DomainsLive
    live "/containers", ContainersLive
    live "/metrics", MetricsLive
  end

  scope "/api", LoadBalancerWeb do
    pipe_through :api

    get "/routes", ApiController, :get_routes
    post "/routes", ApiController, :create_route
    put "/routes/:domain", ApiController, :update_route
    delete "/routes/:domain", ApiController, :delete_route

    get "/containers", ApiController, :get_containers
    post "/containers", ApiController, :create_container
    put "/containers/:name", ApiController, :update_container
    delete "/containers/:name", ApiController, :delete_container

    get "/metrics", ApiController, :get_metrics
    get "/health", ApiController, :health_check
  end
end
