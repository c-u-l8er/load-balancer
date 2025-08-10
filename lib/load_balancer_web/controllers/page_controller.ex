defmodule LoadBalancerWeb.PageController do
  use LoadBalancerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
