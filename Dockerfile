# ── Stage 1: Build client (Gleam → JavaScript, bundled via lustre_dev_tools) ──
FROM ghcr.io/gleam-lang/gleam:v1.6.0-erlang-alpine AS client-build

WORKDIR /client

# Copy client project
COPY client/gleam.toml .
COPY client/src ./src

# Download deps and build the two Lustre apps
RUN gleam deps download

# Build public page (entry: src/app.gleam)
RUN gleam run -m lustre/dev build --outdir=/output -- src/app.gleam

# Build admin page (entry: src/admin.gleam)
RUN gleam run -m lustre/dev build --outdir=/output -- src/admin.gleam

# ── Stage 2: Build server (Gleam → Erlang OTP release) ────────────────────────
FROM ghcr.io/gleam-lang/gleam:v1.6.0-erlang-alpine AS server-build

WORKDIR /app

# Copy server project
COPY gleam.toml .
COPY src ./src

# Copy compiled client assets into priv/static
COPY priv/static ./priv/static
COPY --from=client-build /output/app.mjs    ./priv/static/app.mjs
COPY --from=client-build /output/admin.mjs  ./priv/static/admin.mjs

# Install server deps and produce an Erlang shipment
RUN gleam deps download
RUN gleam export erlang-shipment

# ── Stage 3: Runtime image ────────────────────────────────────────────────────
FROM erlang:27-alpine

WORKDIR /app

COPY --from=server-build /app/build/erlang-shipment .

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "karaoke"]
