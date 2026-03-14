import gleam/dynamic
import gleam/erlang/process.{type Subject}
import gleam/http.{Delete, Get, Post, Put}
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import wisp.{type Request, type Response}
import karaoke/queue.{type Message}
import karaoke/pages

pub fn handle_request(req: Request, actor: Subject(Message)) -> Response {
  use req <- wisp.log_request(req)
  use req <- wisp.rescue_crashes(req)
  use req <- wisp.serve_static(req, under: "/static", from: "./priv/static")

  case wisp.path_segments(req) {
    [] -> handle_index(req)
    ["admin"] -> handle_admin(req)
    ["api", "queue"] -> handle_queue(req, actor)
    ["api", "submit"] -> handle_submit(req, actor)
    ["api", "queue", id_str, "move"] -> handle_move(req, actor, id_str)
    ["api", "queue", id_str] -> handle_queue_item(req, actor, id_str)
    _ -> wisp.not_found()
  }
}

fn handle_index(_req: Request) -> Response {
  wisp.html_response(pages.public_page(), 200)
}

fn handle_admin(_req: Request) -> Response {
  wisp.html_response(pages.admin_page(), 200)
}

// GET /api/queue — return all submissions as JSON
fn handle_queue(req: Request, actor: Subject(Message)) -> Response {
  case req.method {
    Get -> {
      let submissions = queue.get_all(actor)
      let body =
        json.array(submissions, fn(s) {
          json.object([
            #("id", json.int(s.id)),
            #("name", json.string(s.name)),
            #("song", json.string(s.song)),
          ])
        })
      json_response(body, 200)
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

// POST /api/submit — add a new submission
fn handle_submit(req: Request, actor: Subject(Message)) -> Response {
  case req.method {
    Post -> {
      use json_body <- wisp.require_json(req)
      let result = {
        use name <- result.try(
          json_body
          |> dynamic.field("name", dynamic.string),
        )
        use song <- result.try(
          json_body
          |> dynamic.field("song", dynamic.string),
        )
        Ok(#(name, song))
      }
      case result {
        Ok(#(name, song)) -> {
          let name = string.trim(name)
          let song = string.trim(song)
          case name == "" || song == "" {
            True ->
              json_response(
                json.object([
                  #("error", json.string("Name and song are required")),
                ]),
                400,
              )
            False -> {
              let id = queue.add(actor, name, song)
              json_response(
                json.object([
                  #("id", json.int(id)),
                  #("message", json.string("Added to queue!")),
                ]),
                201,
              )
            }
          }
        }
        Error(_) ->
          json_response(
            json.object([#("error", json.string("Invalid request body"))]),
            400,
          )
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

// PUT /api/queue/:id/move — move a submission up or down
fn handle_move(
  req: Request,
  actor: Subject(Message),
  id_str: String,
) -> Response {
  case req.method {
    Put -> {
      case int.parse(id_str) {
        Error(_) ->
          json_response(
            json.object([#("error", json.string("Invalid id"))]),
            400,
          )
        Ok(id) -> {
          use json_body <- wisp.require_json(req)
          let dir_result = dynamic.field("direction", dynamic.string)(json_body)
          case dir_result {
            Error(_) ->
              json_response(
                json.object([
                  #("error", json.string("direction field required")),
                ]),
                400,
              )
            Ok(dir_str) -> {
              let direction = case dir_str {
                "up" -> Ok(queue.Up)
                "down" -> Ok(queue.Down)
                _ -> Error("direction must be 'up' or 'down'")
              }
              case direction {
                Error(msg) ->
                  json_response(
                    json.object([#("error", json.string(msg))]),
                    400,
                  )
                Ok(dir) -> {
                  case queue.move(actor, id, dir) {
                    Ok(Nil) ->
                      json_response(
                        json.object([#("ok", json.bool(True))]),
                        200,
                      )
                    Error(reason) ->
                      json_response(
                        json.object([#("error", json.string(reason))]),
                        422,
                      )
                  }
                }
              }
            }
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([Put])
  }
}

// DELETE /api/queue/:id — remove a submission
fn handle_queue_item(
  req: Request,
  actor: Subject(Message),
  id_str: String,
) -> Response {
  case req.method {
    Delete -> {
      case int.parse(id_str) {
        Error(_) ->
          json_response(
            json.object([#("error", json.string("Invalid id"))]),
            400,
          )
        Ok(id) -> {
          case queue.remove(actor, id) {
            Ok(Nil) ->
              json_response(json.object([#("ok", json.bool(True))]), 200)
            Error(reason) ->
              json_response(
                json.object([#("error", json.string(reason))]),
                404,
              )
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([Delete])
  }
}

// Helpers

fn json_response(body: json.Json, status: Int) -> Response {
  wisp.json_response(json.to_string(body), status)
}
