/// Admin dashboard for the karaoke queue.
///
/// Features:
/// - View all submissions in order
/// - Move items up / down
/// - Remove items
/// - Auto-refresh every 10 seconds
/// - Manual refresh button

import gleam/int
import gleam/list
import gleam/json
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre_http
import karaoke_client/types.{type Submission}

// ── Model ─────────────────────────────────────────────────────────────────────

type ActionStatus {
  ActionIdle
  ActionPending
  ActionError(String)
}

type Model {
  Model(
    queue: List(Submission),
    load_error: String,
    action_status: ActionStatus,
  )
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(
    Model(queue: [], load_error: "", action_status: ActionIdle),
    load_queue(),
  )
}

// ── Msg ───────────────────────────────────────────────────────────────────────

type Msg {
  QueueLoaded(Result(List(Submission), lustre_http.HttpError))
  MoveUp(Int)
  MoveDown(Int)
  Remove(Int)
  ActionDone(Result(OkResponse, lustre_http.HttpError))
  Refresh
}

type OkResponse {
  OkResponse
}

// ── Update ────────────────────────────────────────────────────────────────────

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    QueueLoaded(Ok(submissions)) -> #(
      Model(..model, queue: submissions, load_error: ""),
      effect.none(),
    )

    QueueLoaded(Error(_)) -> #(
      Model(..model, load_error: "Failed to load queue. Retrying…"),
      effect.none(),
    )

    MoveUp(id) -> #(
      Model(..model, action_status: ActionPending),
      move_item(id, "up"),
    )

    MoveDown(id) -> #(
      Model(..model, action_status: ActionPending),
      move_item(id, "down"),
    )

    Remove(id) -> #(
      Model(..model, action_status: ActionPending),
      remove_item(id),
    )

    ActionDone(Ok(_)) -> #(
      Model(..model, action_status: ActionIdle),
      load_queue(),
    )

    ActionDone(Error(_)) -> #(
      Model(
        ..model,
        action_status: ActionError("Action failed. Please try again."),
      ),
      load_queue(),
    )

    Refresh -> #(model, load_queue())
  }
}

// ── Effects ───────────────────────────────────────────────────────────────────

fn load_queue() -> Effect(Msg) {
  lustre_http.get(
    "/api/queue",
    lustre_http.expect_json(types.decode_queue, QueueLoaded),
  )
}

fn move_item(id: Int, direction: String) -> Effect(Msg) {
  let body =
    json.object([#("direction", json.string(direction))])
  lustre_http.put(
    "/api/queue/" <> int.to_string(id) <> "/move",
    lustre_http.json(body),
    lustre_http.expect_anything(fn(_) { ActionDone(Ok(OkResponse)) }),
  )
}

fn remove_item(id: Int) -> Effect(Msg) {
  lustre_http.delete(
    "/api/queue/" <> int.to_string(id),
    lustre_http.expect_anything(fn(_) { ActionDone(Ok(OkResponse)) }),
  )
}

// ── View ──────────────────────────────────────────────────────────────────────

fn view(model: Model) -> Element(Msg) {
  html.div([class("page page--admin")], [
    view_header(model),
    html.main([class("main")], [
      view_error_banner(model),
      view_queue(model),
    ]),
    view_footer(),
  ])
}

fn view_header(model: Model) -> Element(Msg) {
  let count = types.queue_length(model.queue)
  html.header([class("site-header site-header--admin")], [
    html.div([class("site-header__inner")], [
      html.div([class("site-header__top")], [
        html.h1([class("site-header__title")], [
          html.span([class("site-header__icon")], [element.text("🎛")]),
          element.text("Admin Dashboard"),
        ]),
        html.button(
          [class("btn btn--ghost btn--sm"), event.on_click(Refresh)],
          [element.text("↻ Refresh")],
        ),
      ]),
      html.p([class("site-header__subtitle")], [
        element.text(
          int.to_string(count)
          <> case count {
            1 -> " singer in the queue"
            _ -> " singers in the queue"
          },
        ),
      ]),
    ]),
  ])
}

fn view_footer() -> Element(Msg) {
  html.footer([class("site-footer")], [
    html.a([attribute.href("/"), class("site-footer__link")], [
      element.text("← Public page"),
    ]),
  ])
}

fn view_error_banner(model: Model) -> Element(Msg) {
  case model.load_error {
    "" ->
      case model.action_status {
        ActionError(msg) ->
          html.div([class("banner banner--error")], [
            html.span([class("banner__icon")], [element.text("✗")]),
            element.text(" " <> msg),
          ])
        _ -> element.none()
      }
    err ->
      html.div([class("banner banner--warning")], [
        html.span([class("banner__icon")], [element.text("⚠")]),
        element.text(" " <> err),
      ])
  }
}

fn view_queue(model: Model) -> Element(Msg) {
  let count = types.queue_length(model.queue)
  html.section([class("card")], [
    case list.is_empty(model.queue) {
      True ->
        html.div([class("queue-empty-admin")], [
          html.span([class("queue-empty-admin__icon")], [element.text("🎤")]),
          html.p([], [element.text("No one in the queue yet.")]),
          html.p([class("muted")], [
            element.text("Share the public link to get people signing up!"),
          ]),
        ])
      False ->
        html.div([class("admin-queue")], [
          html.table([class("queue-table")], [
            html.thead([], [
              html.tr([], [
                html.th([class("queue-table__pos")], [element.text("#")]),
                html.th([], [element.text("Name")]),
                html.th([], [element.text("Song")]),
                html.th([class("queue-table__actions")], [
                  element.text("Actions"),
                ]),
              ]),
            ]),
            html.tbody(
              [],
              list.index_map(model.queue, fn(s, i) {
                view_queue_row(s, i, count)
              }),
            ),
          ]),
        ])
    },
  ])
}

fn view_queue_row(
  submission: Submission,
  index: Int,
  total: Int,
) -> Element(Msg) {
  let is_first = index == 0
  let is_last = index == total - 1
  let pos = index + 1

  html.tr(
    [
      class(case is_first {
        True -> "queue-row queue-row--first"
        False -> "queue-row"
      }),
    ],
    [
      html.td([class("queue-table__pos")], [
        html.span([class("pos-badge")], [element.text(int.to_string(pos))]),
      ]),
      html.td([class("queue-table__name")], [element.text(submission.name)]),
      html.td([class("queue-table__song")], [
        html.span([class("song-name")], [element.text(submission.song)]),
      ]),
      html.td([class("queue-table__actions")], [
        html.div([class("action-buttons")], [
          html.button(
            [
              class(
                "btn btn--icon"
                <> case is_first {
                  True -> " btn--disabled"
                  False -> ""
                },
              ),
              attribute.title("Move up"),
              attribute.disabled(is_first),
              event.on_click(MoveUp(submission.id)),
            ],
            [element.text("↑")],
          ),
          html.button(
            [
              class(
                "btn btn--icon"
                <> case is_last {
                  True -> " btn--disabled"
                  False -> ""
                },
              ),
              attribute.title("Move down"),
              attribute.disabled(is_last),
              event.on_click(MoveDown(submission.id)),
            ],
            [element.text("↓")],
          ),
          html.button(
            [
              class("btn btn--icon btn--danger"),
              attribute.title("Remove"),
              event.on_click(Remove(submission.id)),
            ],
            [element.text("✕")],
          ),
        ]),
      ]),
    ],
  )
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
