/// Public karaoke submission page.
///
/// Features:
/// - Submit name + song to the queue
/// - Pre-populate name from localStorage on load
/// - Save name to localStorage on successful submit
/// - Show live queue below the form
/// - Success/error flash messages

import gleam/dynamic
import gleam/int
import gleam/list
import gleam/string
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre_http
import karaoke_client/ffi
import karaoke_client/types.{type Submission}

// ── Model ─────────────────────────────────────────────────────────────────────

type Status {
  Idle
  Submitting
  Success(String)
  Failure(String)
}

type Model {
  Model(
    name: String,
    song: String,
    status: Status,
    queue: List(Submission),
    queue_error: String,
    position: Int,
  )
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let saved_name = ffi.get_local_storage("karaoke_name")
  #(
    Model(
      name: saved_name,
      song: "",
      status: Idle,
      queue: [],
      queue_error: "",
      position: 0,
    ),
    load_queue(),
  )
}

// ── Msg ───────────────────────────────────────────────────────────────────────

type Msg {
  UpdateName(String)
  UpdateSong(String)
  SubmitForm
  SubmitResponse(Result(SubmitResult, lustre_http.HttpError))
  QueueLoaded(Result(List(Submission), lustre_http.HttpError))
  ClearStatus
}

type SubmitResult {
  SubmitResult(id: Int, message: String)
}

// ── Update ────────────────────────────────────────────────────────────────────

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UpdateName(value) -> #(Model(..model, name: value), effect.none())
    UpdateSong(value) -> #(Model(..model, song: value), effect.none())

    SubmitForm -> {
      let name = trim(model.name)
      let song = trim(model.song)
      case name == "" || song == "" {
        True -> #(
          Model(..model, status: Failure("Please fill in both fields.")),
          effect.none(),
        )
        False -> #(
          Model(..model, status: Submitting),
          submit_song(name, song),
        )
      }
    }

    SubmitResponse(Ok(res)) -> {
      ffi.set_local_storage("karaoke_name", model.name)
      #(
        Model(..model, song: "", status: Success(res.message), position: res.id),
        load_queue(),
      )
    }

    SubmitResponse(Error(_)) -> #(
      Model(
        ..model,
        status: Failure("Something went wrong. Please try again."),
      ),
      effect.none(),
    )

    QueueLoaded(Ok(submissions)) -> #(
      Model(..model, queue: submissions, queue_error: ""),
      effect.none(),
    )

    QueueLoaded(Error(_)) -> #(
      Model(..model, queue_error: "Could not load the queue."),
      effect.none(),
    )

    ClearStatus -> #(Model(..model, status: Idle), effect.none())
  }
}

// ── Effects ───────────────────────────────────────────────────────────────────

fn load_queue() -> Effect(Msg) {
  lustre_http.get(
    "/api/queue",
    lustre_http.expect_json(types.decode_queue, QueueLoaded),
  )
}

fn submit_song(name: String, song: String) -> Effect(Msg) {
  let body = types.encode_submission_request(name, song)
  lustre_http.post(
    "/api/submit",
    lustre_http.json(body),
    lustre_http.expect_json(decode_submit_result, SubmitResponse),
  )
}

fn decode_submit_result(
  dyn: dynamic.Dynamic,
) -> Result(SubmitResult, List(dynamic.DecodeError)) {
  dynamic.decode2(
    SubmitResult,
    dynamic.field("id", dynamic.int),
    dynamic.field("message", dynamic.string),
  )(dyn)
}

// ── View ──────────────────────────────────────────────────────────────────────

fn view(model: Model) -> Element(Msg) {
  html.div([class("page page--public")], [
    view_header(),
    html.main([class("main")], [
      view_form(model),
      view_queue(model),
    ]),
    view_footer(),
  ])
}

fn view_header() -> Element(Msg) {
  html.header([class("site-header")], [
    html.div([class("site-header__inner")], [
      html.h1([class("site-header__title")], [
        html.span([class("site-header__icon")], [element.text("🎤")]),
        element.text("Karaoke Queue"),
      ]),
      html.p([class("site-header__subtitle")], [
        element.text("Pick a song and get in line!"),
      ]),
    ]),
  ])
}

fn view_footer() -> Element(Msg) {
  html.footer([class("site-footer")], [
    html.p([], [element.text("✨ Have fun singing!")]),
  ])
}

fn view_form(model: Model) -> Element(Msg) {
  let is_submitting = model.status == Submitting
  html.section([class("card form-card")], [
    html.h2([class("card__title")], [element.text("Add yourself to the queue")]),
    view_status_banner(model),
    html.form(
      [
        class("submission-form"),
        event.on_submit(SubmitForm),
      ],
      [
        html.div([class("form-group")], [
          html.label([attr_for("name"), class("form-label")], [
            element.text("Your name"),
          ]),
          html.input([
            id("name"),
            class("form-input"),
            attribute.type_("text"),
            attribute.value(model.name),
            attribute.placeholder("e.g. Taylor Swift"),
            attribute.required(True),
            attribute.disabled(is_submitting),
            event.on_input(UpdateName),
          ]),
        ]),
        html.div([class("form-group")], [
          html.label([attr_for("song"), class("form-label")], [
            element.text("Song name"),
          ]),
          html.input([
            id("song"),
            class("form-input"),
            attribute.type_("text"),
            attribute.value(model.song),
            attribute.placeholder("e.g. Shake It Off"),
            attribute.required(True),
            attribute.disabled(is_submitting),
            event.on_input(UpdateSong),
          ]),
        ]),
        html.button(
          [
            class("btn btn--primary"),
            attribute.type_("submit"),
            attribute.disabled(is_submitting),
          ],
          [
            case is_submitting {
              True -> element.text("Adding…")
              False -> element.text("Join the Queue 🎵")
            },
          ],
        ),
      ],
    ),
  ])
}

fn view_status_banner(model: Model) -> Element(Msg) {
  case model.status {
    Idle -> element.none()
    Submitting -> element.none()
    Success(msg) ->
      html.div([class("banner banner--success")], [
        html.span([class("banner__icon")], [element.text("✓")]),
        element.text(" " <> msg),
      ])
    Failure(msg) ->
      html.div([class("banner banner--error")], [
        html.span([class("banner__icon")], [element.text("✗")]),
        element.text(" " <> msg),
      ])
  }
}

fn view_queue(model: Model) -> Element(Msg) {
  let count = types.queue_length(model.queue)
  html.section([class("card queue-card")], [
    html.div([class("queue-header")], [
      html.h2([class("card__title")], [element.text("Current Queue")]),
      html.span([class("queue-badge")], [
        element.text(int.to_string(count) <> " waiting"),
      ]),
    ]),
    case model.queue_error {
      "" -> element.none()
      err ->
        html.p([class("queue-error")], [element.text(err)])
    },
    case list.is_empty(model.queue) {
      True ->
        html.p([class("queue-empty")], [
          element.text("The queue is empty — be the first to sign up! 🌟"),
        ])
      False ->
        html.ol([class("queue-list")], [
          ..list.index_map(model.queue, fn(s, _i) { view_queue_item(s) })
        ])
    },
  ])
}

fn view_queue_item(submission: Submission) -> Element(Msg) {
  html.li([class("queue-item")], [
    html.span([class("queue-item__name")], [element.text(submission.name)]),
    html.span([class("queue-item__sep")], [element.text("—")]),
    html.span([class("queue-item__song")], [element.text(submission.song)]),
  ])
}

// ── Entry ─────────────────────────────────────────────────────────────────────

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// ── Utilities ─────────────────────────────────────────────────────────────────

fn class(name: String) -> Attribute(msg) {
  attribute.class(name)
}

fn id(name: String) -> Attribute(msg) {
  attribute.id(name)
}

fn attr_for(target: String) -> Attribute(msg) {
  attribute.for(target)
}

fn trim(s: String) -> String {
  string.trim(s)
}
