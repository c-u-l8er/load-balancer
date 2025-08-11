# Use the official Elixir image as base
FROM elixir:1.15-alpine

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm

# Set working directory
WORKDIR /app

# Install hex package manager and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies with better error handling
RUN mix deps.get --only prod && \
    mix deps.compile --force

# Copy source code
COPY . .

# Set environment to production for compilation
ENV MIX_ENV=prod

# Build the application
RUN mix compile

# Create a release
RUN mix release

# Create a new stage for runtime
FROM elixir:1.15-alpine

# Install runtime dependencies (no build tools)
RUN apk add --no-cache \
    openssl \
    ca-certificates \
    ncurses-libs

# Create app user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app

# Set working directory
WORKDIR /app

# Copy release from build stage
COPY --from=0 /app/_build/prod/rel/load_balancer ./

# Create necessary directories
RUN mkdir -p /app/config /app/certs /app/data && \
    chown -R app:app /app

# Switch to app user
USER app

# Expose ports
EXPOSE 8080 4000

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=8080
ENV WEB_PORT=4000

# Start the application
CMD ["bin/load_balancer", "start"]
