import gleam/dynamic
import gleam/json
import gleam/list

pub type Submission {
  Submission(id: Int, name: String, song: String)
}

pub fn decode_submission(
  dyn: dynamic.Dynamic,
) -> Result(Submission, List(dynamic.DecodeError)) {
  dynamic.decode3(
    Submission,
    dynamic.field("id", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("song", dynamic.string),
  )(dyn)
}

pub fn decode_queue(
  dyn: dynamic.Dynamic,
) -> Result(List(Submission), List(dynamic.DecodeError)) {
  dynamic.list(decode_submission)(dyn)
}

pub fn encode_submission_request(name: String, song: String) -> json.Json {
  json.object([
    #("name", json.string(name)),
    #("song", json.string(song)),
  ])
}

pub fn queue_length(queue: List(Submission)) -> Int {
  list.length(queue)
}
