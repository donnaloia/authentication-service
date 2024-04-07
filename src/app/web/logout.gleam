import app/web.{type Context}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
import gleam/http/request.{get_header}
import gleam/json
import gleam/list
import gleam/dict
import gleam/result.{try}
import wisp.{type Request, type Response}
import gleam/pgo
import gleam/string_builder.{type StringBuilder}
import app/sql/queries
import gleam/int
import antigone
import gleam/bit_array
import gleam/io
import gleam/string
import gwt.{type Jwt, type Unverified, type Verified}

pub fn logout_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> logout(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn logout(req: Request, ctx: Context) -> Response {
  //   // Check http header for access-token
  let auth_token = get_header(req, "Authorization")
  let token =
    case auth_token {
      Ok(auth_token) -> string.drop_left(auth_token, 8)
      Error(_) -> "No token provided"
    }
    |> io.debug()
  io.debug("auth_token is: ")

  let delete_return_type = dynamic.dynamic

  let assert Ok(response) =
    pgo.execute(
      queries.delete_access_token,
      ctx.db,
      [pgo.text(token)],
      delete_return_type,
    )

  json.object([#("message", json.string("Successfully logged out"))])
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
