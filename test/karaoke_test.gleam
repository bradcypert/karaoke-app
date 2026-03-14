import gleam/erlang/process
import gleeunit
import gleeunit/should
import karaoke/queue

pub fn main() {
  gleeunit.main()
}

pub fn queue_add_test() {
  let assert Ok(actor) = queue.start()
  let id = queue.add(actor, "Alice", "Shake It Off")
  id |> should.equal(1)

  let items = queue.get_all(actor)
  items |> should.not_equal([])
}

pub fn queue_move_up_test() {
  let assert Ok(actor) = queue.start()
  let _id1 = queue.add(actor, "Alice", "Song A")
  let id2 = queue.add(actor, "Bob", "Song B")

  // Bob is #2, move him up to #1
  queue.move(actor, id2, queue.Up)
  |> should.equal(Ok(Nil))

  let items = queue.get_all(actor)
  let assert [first, ..] = items
  first.name |> should.equal("Bob")
}

pub fn queue_remove_test() {
  let assert Ok(actor) = queue.start()
  let id = queue.add(actor, "Alice", "Song A")
  queue.remove(actor, id) |> should.equal(Ok(Nil))
  queue.get_all(actor) |> should.equal([])
}

pub fn queue_remove_missing_test() {
  let assert Ok(actor) = queue.start()
  let result = queue.remove(actor, 999)
  result |> should.be_error()
}
