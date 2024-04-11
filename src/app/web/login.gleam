import app/web.{type Context}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
import app/users/types
import gleam/json
import gleam/list
import gleam/result
import wisp.{type Request, type Response}
import gleam/pgo
import app/sql/queries
import app/auth/refresh_tokens
import app/auth/access_tokens
import gleam/int
import antigone
import gleam/bit_array
import birl

pub fn login_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> login(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn login(req: Request, ctx: Context) -> Response {
  // Read the JSON from the request body.
  use json <- wisp.require_json(req)
  // Decode the JSON into a User record.
  let assert Ok(user) = decode_login(json)

  let assert Ok(db_response) =
    pgo.execute(
      queries.get_user_by_username,
      ctx.db,
      [pgo.text(user.username)],
      types.user_return_type(),
    )

  case list.first(db_response.rows) {
    Ok(#(id, _username, password, _email)) -> {
      let signed_jwt = access_tokens.create_access_token(ctx, id)
      let refresh_token = refresh_tokens.get_refresh_token(ctx, id)
      let expires_at = int.to_string(birl.to_unix(birl.now()) + 900)
      let password_utf = bit_array.from_string(user.password)
      let verified_pass = antigone.verify(password_utf, password)

      case verified_pass {
        True -> {
          json.object([
            #("access_token", json.string(signed_jwt)),
            #("expires_at", json.string(expires_at)),
            #("refresh_token", json.string(refresh_token)),
          ])
          |> json.to_string_builder()
          |> wisp.json_response(200)
        }
        False -> {
          json.object([#("error", json.string("Invalid username or password"))])
          |> json.to_string_builder()
          |> wisp.json_response(401)
        }
      }
    }
    Error(Nil) -> {
      json.object([#("error", json.string("Invalid username or password."))])
      |> json.to_string_builder()
      |> wisp.json_response(401)
    }
  }
}

pub type Login {
  Login(username: String, password: String)
}

fn decode_login(json: Dynamic) -> Result(Login, Nil) {
  let decoder =
    dynamic.decode2(
      Login,
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
    )
  let result = decoder(json)

  result
  |> result.nil_error
}
