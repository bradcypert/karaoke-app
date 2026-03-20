import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

pub type Submission {
  Submission(id: Int, name: String, song: String)
}

pub type Direction {
  Up
  Down
}

pub type Message {
  GetAll(reply: Subject(List(Submission)))
  Add(reply: Subject(Int), name: String, song: String)
  Move(reply: Subject(Result(Nil, String)), id: Int, direction: Direction)
  Remove(reply: Subject(Result(Nil, String)), id: Int)
}

type State {
  State(items: List(Submission), next_id: Int)
}

pub fn start() -> Result(Subject(Message), actor.StartError) {
  let assert Ok(started) =
    actor.new(State(items: [], next_id: 1))
    |> actor.on_message(loop)
    |> actor.start
  Ok(started.data)
}

fn loop(state: State, msg: Message) -> actor.Next(State, Message) {
  case msg {
    GetAll(reply) -> {
      process.send(reply, state.items)
      actor.continue(state)
    }

    Add(reply, name, song) -> {
      let id = state.next_id
      let item = Submission(id: id, name: name, song: song)
      let new_state =
        State(
          items: list.append(state.items, [item]),
          next_id: id + 1,
        )
      process.send(reply, id)
      actor.continue(new_state)
    }

    Move(reply, id, direction) -> {
      case move_item(state.items, id, direction) {
        Ok(new_items) -> {
          process.send(reply, Ok(Nil))
          actor.continue(State(..state, items: new_items))
        }
        Error(reason) -> {
          process.send(reply, Error(reason))
          actor.continue(state)
        }
      }
    }

    Remove(reply, id) -> {
      case list.any(state.items, fn(s) { s.id == id }) {
        True -> {
          let new_items = list.filter(state.items, fn(s) { s.id != id })
          process.send(reply, Ok(Nil))
          actor.continue(State(..state, items: new_items))
        }
        False -> {
          process.send(reply, Error("Submission not found"))
          actor.continue(state)
        }
      }
    }
  }
}

// Public API helpers

pub fn get_all(actor: Subject(Message)) -> List(Submission) {
  process.call(actor, 1000, fn(reply) { GetAll(reply) })
}

pub fn add(actor: Subject(Message), name: String, song: String) -> Int {
  process.call(actor, 1000, fn(reply) { Add(reply, name, song) })
}

pub fn move(
  actor: Subject(Message),
  id: Int,
  direction: Direction,
) -> Result(Nil, String) {
  process.call(actor, 1000, fn(reply) { Move(reply, id, direction) })
}

pub fn remove(actor: Subject(Message), id: Int) -> Result(Nil, String) {
  process.call(actor, 1000, fn(reply) { Remove(reply, id) })
}

// Internal helpers

fn move_item(
  items: List(Submission),
  id: Int,
  direction: Direction,
) -> Result(List(Submission), String) {
  let indexed = list.index_map(items, fn(item, i) { #(i, item) })
  case list.find(indexed, fn(pair) { pair.1.id == id }) {
    Error(_) -> Error("Submission not found")
    Ok(#(idx, _)) -> {
      let len = list.length(items)
      case direction {
        Up if idx == 0 -> Error("Already at top")
        Down if idx == len - 1 -> Error("Already at bottom")
        Up -> Ok(swap_at(items, idx - 1, idx))
        Down -> Ok(swap_at(items, idx, idx + 1))
      }
    }
  }
}

fn swap_at(items: List(Submission), a: Int, b: Int) -> List(Submission) {
  let arr = list.index_map(items, fn(item, i) { #(i, item) })
  let item_a = list.find(arr, fn(p) { p.0 == a })
  let item_b = list.find(arr, fn(p) { p.0 == b })
  case item_a, item_b {
    Ok(#(_, va)), Ok(#(_, vb)) ->
      list.map(arr, fn(p) {
        case p.0 == a, p.0 == b {
          True, _ -> vb
          _, True -> va
          _, _ -> p.1
        }
      })
    _, _ -> items
  }
}
