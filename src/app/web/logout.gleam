import app/web.{type Context}
import app/users/types
import app/auth/check_tokens
import app/sql/queries
import gleam/http.{Get, Post}
import gleam/http/request.{get_header}
import gleam/json
import wisp.{type Request, type Response}
import gleam/pgo
import gleam/string
import gleam/io

pub fn logout_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> logout(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn logout(req: Request, ctx: Context) -> Response {
  let authorized = check_tokens.verify_auth_header(req, ctx)
  case authorized {
    True -> {
      let auth_token = get_header(req, "Authorization")
      let token = case auth_token {
        Ok(auth_token) -> {
          string.drop_left(auth_token, 7)
        }
        Error(_) -> "mi"
      }
      let assert Ok(_) =
        pgo.execute(
          queries.delete_access_token,
          ctx.db,
          [pgo.text(token)],
          types.delete_user_return_type(),
        )
      json.object([#("message", json.string("Successfully logged out."))])
      |> json.to_string_builder()
      |> wisp.json_response(204)
    }
    False -> {
      json.object([
        #("error", json.string("Missing or malformed authorization header.")),
      ])
      |> json.to_string_builder()
      |> wisp.json_response(401)
    }
  }
}
