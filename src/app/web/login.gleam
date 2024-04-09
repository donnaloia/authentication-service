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
import gleam/int
import antigone
import gleam/bit_array
import gleam/io
import gwt
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

  let password_utf = bit_array.from_string(user.password)

  let assert Ok(response) =
    pgo.execute(
      queries.get_user_by_username,
      ctx.db,
      [pgo.text(user.username)],
      types.user_return_type(),
    )

  case list.first(response.rows) {
    Ok(#(id, username, password, email)) -> {
      let signed_jwt = create_access_token(ctx, username, id)
      let expires_at = int.to_string(birl.to_unix(birl.now()) + 900)
      let verified_pass = antigone.verify(password_utf, password)

      case verified_pass {
        True -> {
          json.object([
            #("access_token", json.string(signed_jwt)),
            #("expires_at", json.string(expires_at)),
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

fn create_access_token(ctx: Context, username: String, id: Int) -> String {
  let fifteen_minutes = birl.to_unix(birl.now()) + 900
  let jti = int.random(1000)
  let jwt =
    gwt.new()
    |> gwt.set_subject(username)
    |> gwt.set_issued_at(birl.to_unix(birl.now()))
    |> gwt.set_expiration(fifteen_minutes)
    |> gwt.set_jwt_id(int.to_string(jti))

  let return_type = dynamic.tuple3(dynamic.int, dynamic.int, dynamic.string)
  let delete_return_type = dynamic.dynamic
  let jwt_with_signature = gwt.to_signed_string(jwt, gwt.HS256, ctx.secret_key)
  // Save the token to the database.

  let assert Ok(response) =
    pgo.execute(
      queries.delete_access_token_by_user,
      ctx.db,
      [pgo.int(id)],
      delete_return_type,
    )
  let assert Ok(response) =
    pgo.execute(
      queries.create_access_token,
      ctx.db,
      [pgo.int(id), pgo.text(jwt_with_signature)],
      return_type,
    )

  // return the token
  jwt_with_signature
}
