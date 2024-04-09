import app/web.{type Context}
import app/users/types
import app/sql/queries
import gleam/http.{Get, Post}
import gleam/http/request.{get_header}
import gleam/json
import wisp.{type Request, type Response}
import gleam/pgo
import gleam/string

pub fn logout_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> logout(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn logout(req: Request, ctx: Context) -> Response {
  let auth_token = get_header(req, "Authorization")
  case auth_token {
    Ok(auth_token) -> {
      let token = string.drop_left(auth_token, 8)
      let assert Ok(_) =
        pgo.execute(
          queries.delete_access_token,
          ctx.db,
          [pgo.text(token)],
          types.delete_user_return_type(),
        )
      json.object([#("message", json.string("Successfully logged out"))])
      |> json.to_string_builder()
      |> wisp.json_response(204)
    }
    Error(_) -> {
      json.object([
        #("error", json.string("Missing or malformed authorization header.")),
      ])
      |> json.to_string_builder()
      |> wisp.json_response(401)
    }
  }
}
