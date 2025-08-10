defmodule LoadBalancerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :load_balancer

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_load_balancer_key",
    signing_salt: "zsAoodEZf6K3fZiNJt/5QrTFgSYJil/BjwxIX8O3Q1kp7xhBsyehDhOFt6I5S6w+"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Static,
    at: "/",
    from: :load_balancer,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  plug LoadBalancerWeb.Router
end
