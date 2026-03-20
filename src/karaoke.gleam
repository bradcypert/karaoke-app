import gleam/erlang/process
import gleam/io
import mist
import wisp
import wisp/wisp_mist
import karaoke/queue
import karaoke/router

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(queue_actor) = queue.start()

  let handler = router.handle_request(_, queue_actor)

  io.println("Starting Karaoke Queue on http://localhost:8000")

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new()
    |> mist.port(8000)
    |> mist.start()

  process.sleep_forever()
}
