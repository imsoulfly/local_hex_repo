## Build a production release (builder stage)
FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bookworm-20260112-slim AS build

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV

WORKDIR /app

# Install build tools (esbuild/dart_sass fetch prebuilt binaries, but compilation needs a toolchain)
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ca-certificates && \
  rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

# Cache deps
COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get --only $MIX_ENV && mix deps.compile

# Build assets (runs dart_sass + esbuild + phx.digest via alias)
COPY assets ./assets
COPY priv ./priv
RUN mix assets.deploy

# Compile and build the release
COPY lib ./lib
RUN mix compile && mix release

## Minimal runtime image (bookworm-slim)
FROM debian:bookworm-slim AS app

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    libncurses6 \
    libssl3 \
    libstdc++6 \
    openssl \
    zlib1g && \
  rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  PHX_SERVER=true \
  PHX_STATIC_GZIP=true \
  PORT=4000

WORKDIR /app

RUN groupadd --system --gid 10001 app && \
    useradd  --system --uid 10001 --gid 10001 --home /app --shell /usr/sbin/nologin app && \
    mkdir -p /data/repos /data/storage && \
    chown -R app:app /app /data

COPY --from=build /app/_build/prod/rel/local_hex ./

# Ensure runtime-writable paths exist (commonly mounted as volumes)
RUN mkdir -p /data/repos /data/storage && \
  chown -R app:app /data

USER app

EXPOSE 4000

CMD ["bin/local_hex", "start"]
