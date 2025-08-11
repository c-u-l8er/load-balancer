#!/bin/bash

# Start the production server locally
# This script sets the necessary environment variables and starts the server

echo "Starting Load Balancer in production mode on port 4001..."

# Set environment variables for local production testing
export SECRET_KEY_BASE="GnxSXgDYykilzlTlmuLmg8kmeW+e7wvDvNKfIoHnLkDOfinAX1cuEeitZ4Ae3UJAhZZJim+Bws6Zen352o2fTQ=="
export LIVE_VIEW_SIGNING_SALT="production-signing-salt"
export PHX_HOST="localhost"
export LOAD_BALANCER_WEB_PORT="4001"
export LOAD_BALANCER_PORT="8080"
export LOAD_BALANCER_SSL_CERTS_PATH="./certs"
export LOAD_BALANCER_LOG_LEVEL="info"

# Start the server in production mode
mix phx.server --env prod
