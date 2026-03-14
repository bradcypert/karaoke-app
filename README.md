# Karaoke Queue App

A karaoke song-submission and queue-management app built with **Gleam**, **Lustre**, and **Wisp**.

## Architecture

| Layer | Technology |
|-------|-----------|
| Server | [Gleam](https://gleam.run) + [Wisp](https://hexdocs.pm/wisp) + [Mist](https://hexdocs.pm/mist) (Erlang/OTP) |
| Frontend | [Lustre](https://hexdocs.pm/lustre) (Gleam → JavaScript) |
| State | In-memory OTP Actor (reset on restart) |

### Pages

- **`/`** — Public submission form. Anyone can queue up with their name and song.
  - Name is pre-populated from `localStorage` on return visits.
  - Live queue list shows who's waiting.
- **`/admin`** — Admin dashboard. Reorder or remove entries from the queue.

### API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/queue` | Fetch all submissions |
| `POST` | `/api/submit` | Add a new submission `{ name, song }` |
| `PUT` | `/api/queue/:id/move` | Move entry `{ direction: "up"\|"down" }` |
| `DELETE` | `/api/queue/:id` | Remove an entry |

## Development

### Prerequisites

- [Gleam](https://gleam.run/getting-started/) ≥ 1.6
- Erlang/OTP ≥ 26

### Run locally

```sh
./build.sh
```

This will:
1. Install server + client dependencies
2. Compile the Lustre apps to `priv/static/app.mjs` and `priv/static/admin.mjs`
3. Start the server on **http://localhost:8000**

### Run tests

```sh
gleam test
```

## Docker

```sh
docker build -t karaoke-app .
docker run -p 8000:8000 karaoke-app
```

## Project Structure

```
├── gleam.toml              # Server project (Erlang target)
├── src/
│   ├── karaoke.gleam       # Entry point
│   └── karaoke/
│       ├── queue.gleam     # OTP Actor — in-memory queue
│       ├── router.gleam    # Wisp HTTP router + handlers
│       └── pages.gleam     # HTML shell templates
├── client/                 # Frontend project (JavaScript target)
│   ├── gleam.toml
│   └── src/
│       ├── app.gleam               # Public page Lustre app
│       ├── admin.gleam             # Admin dashboard Lustre app
│       ├── ffi.js                  # localStorage FFI
│       └── karaoke_client/
│           ├── types.gleam         # Shared Submission type + decoders
│           └── ffi.gleam           # Gleam FFI declarations
├── priv/
│   └── static/
│       ├── styles.css      # App styles
│       ├── app.mjs         # Compiled public page (generated)
│       └── admin.mjs       # Compiled admin page (generated)
├── test/
│   └── karaoke_test.gleam  # Unit tests
├── build.sh                # Local dev build + run script
└── Dockerfile              # Multi-stage production build
```
