#!/usr/bin/env sh
# Build script for local development.
# Compiles client Lustre apps and copies assets, then runs the server.
set -e

echo "==> Installing server dependencies…"
gleam deps download

echo "==> Installing client dependencies…"
(cd client && gleam deps download)

echo "==> Building client (public page)…"
(cd client && gleam run -m lustre/dev build --outdir=../priv/static -- src/app.gleam)

echo "==> Building client (admin page)…"
(cd client && gleam run -m lustre/dev build --outdir=../priv/static -- src/admin.gleam)

echo "==> Starting server on http://localhost:8000"
gleam run
