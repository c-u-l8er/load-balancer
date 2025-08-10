defmodule LoadBalancer.Endpoint do
  @moduledoc """
  Main HTTP endpoint for the load balancer.
  Handles incoming requests and routes them to appropriate Docker containers.
  """

  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  # Health check endpoint for the load balancer itself
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "healthy", timestamp: DateTime.utc_now()}))
  end

  # Metrics endpoint
  get "/metrics" do
    metrics = LoadBalancer.Monitor.get_metrics()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(metrics))
  end

  # Catch-all route for domain-based routing
  match _ do
    handle_request(conn)
  end

  # Private Functions

  defp handle_request(conn) do
    # Extract domain from Host header
    domain = extract_domain(conn)

    case LoadBalancer.Router.route_request(domain, conn.request_path, conn.req_headers) do
      {:ok, container_endpoint} ->
        # Route request to container
        route_to_container(conn, container_endpoint)

      {:error, reason} ->
        Logger.error("Failed to route request for domain #{domain}: #{reason}")
        send_error_response(conn, 502, "Bad Gateway")
    end
  end

  defp extract_domain(conn) do
    case get_req_header(conn, "host") do
      [host | _] -> host |> String.split(":") |> List.first()
      [] -> "localhost"
    end
  end

  defp route_to_container(conn, container_endpoint) do
    # Increment connection count for the container
    LoadBalancer.Strategy.increment_connection_count(container_endpoint)

    try do
      # Forward request to container
      forward_request(conn, container_endpoint)
    after
      # Decrement connection count
      LoadBalancer.Strategy.decrement_connection_count(container_endpoint)
    end
  end

  defp forward_request(conn, container_endpoint) do
    # Build target URL
    target_url = build_target_url(container_endpoint, conn.request_path, conn.query_string)

    # Prepare request options
    opts = [
      method: String.to_atom(conn.method),
      headers: conn.req_headers,
      body: get_request_body(conn),
      timeout: 30_000
    ]

    # Make request to container
    case HTTPoison.request(opts[:method], target_url, opts[:body], opts[:headers], opts) do
      {:ok, %{status_code: status_code, headers: headers, body: body}} ->
        # Forward response back to client
        conn
        |> put_resp_headers(headers)
        |> send_resp(status_code, body)

      {:error, %{reason: reason}} ->
        Logger.error("Failed to forward request to #{container_endpoint}: #{reason}")
        send_error_response(conn, 502, "Bad Gateway")
    end
  end

  defp build_target_url(container_endpoint, path, query_string) do
    base_url = "http://#{container_endpoint}"
    full_path = if query_string != "", do: "#{path}?#{query_string}", else: path
    base_url <> full_path
  end

  defp get_request_body(conn) do
    case conn.body_params do
      %{} = params -> Jason.encode!(params)
      _ -> ""
    end
  end

  defp put_resp_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, acc ->
      put_resp_header(acc, key, value)
    end)
  end

  defp send_error_response(conn, status_code, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(%{error: message}))
  end
end
