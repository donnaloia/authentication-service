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

    // TODO: add access/refresh token generation logic
    let user = case list.first(response.rows) {
      Ok(#(id, username, password, email)) -> {
        let p = antigone.verify(password_utf, password)
        let result = case p {
          True ->
            json.object([
              #(
                "access_token",
                json.string(
                  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (access token)",
                ),
              ),
              #("expires_at", json.string(username)),
            ])
          False ->
            json.object([
              #("error", json.string("Invalid username or password")),
            ])
        }
      }
      Error(Nil) -> {
        // Handle the error here, for example, return a JSON object with an error message
        json.object([#("error", json.string("Invalid username or password"))])
      }
    }
  }
  let body = json.to_string_builder(result)
  wisp.json_response(body, 200)
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
