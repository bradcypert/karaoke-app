from denoland/deno:alpine-2.0.2

workdir /app

copy . .
run deno cache main.ts
run deno task build

user deno
expose 8000

cmd ["run", "-A", "main.ts"]
