import app/web.{type Context}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
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
import gwt.{type Jwt}
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

  let result = {
    // This is the decoder for the value returned by the 'users' sql query
    let return_type =
      dynamic.tuple4(
        dynamic.int,
        dynamic.string,
        dynamic.string,
        dynamic.string,
      )

    let password_utf = bit_array.from_string(user.password)

    let assert Ok(response) =
      pgo.execute(
        queries.get_user_by_username,
        ctx.db,
        [pgo.text(user.username)],
        return_type,
      )

    let user = case list.first(response.rows) {
      Ok(#(id, username, password, email)) -> {
        let signed_jwt = create_access_token(ctx, username, id)
        let verified_pass = antigone.verify(password_utf, password)
        let result = case verified_pass {
          True ->
            json.object([
              #("access_token", json.string(signed_jwt)),
              #("expires_at", json.string(username)),
            ])
          False ->
            json.object([
              #("error", json.string("Invalid username or password")),
            ])
        }
      }
      Error(Nil) -> {
        json.object([#("error", json.string("Invalid username or password"))])
      }
    }
  }
  json.to_string_builder(result)
  |> wisp.json_response(200)
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

  // In this example we are not going to be reporting specific errors to the
  // user, so we can discard the error and replace it with Nil.
  result
  |> result.nil_error
}

fn create_access_token(ctx: Context, username: String, id: Int) -> String {
  let five_minutes = birl.to_unix(birl.now()) + 300
  let jti = int.random(1000)
  let jwt =
    gwt.new()
    |> gwt.set_subject(username)
    |> gwt.set_issued_at(birl.to_unix(birl.now()))
    |> gwt.set_expiration(five_minutes)
    |> gwt.set_jwt_id(int.to_string(jti))

  let return_type = dynamic.tuple3(dynamic.int, dynamic.int, dynamic.string)

  let jwt_with_signature = gwt.to_signed_string(jwt, gwt.HS256, "secret_key")
  // Save the token to the database.
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
