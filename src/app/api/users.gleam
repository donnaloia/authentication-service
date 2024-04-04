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

// This is the type of the records that we are going to be working with.
pub type User {
  User(username: String, password: String, email: String)
}

pub fn get_users_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> list_users(ctx)
    Post -> create_user(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn list_users(ctx: Context) -> Response {
  let result = {
    // This is the decoder for the value returned by the 'users' sql query
    let return_type =
      dynamic.tuple4(
        dynamic.int,
        dynamic.string,
        dynamic.string,
        dynamic.string,
      )

    let assert Ok(response) =
      pgo.execute(queries.get_users, ctx.db, [], return_type)

    let users =
      json.array(response.rows, fn(row) {
        case row {
          #(id, username, password, email) ->
            json.object([
              #("id", json.int(id)),
              #("username", json.string(username)),
              #("password", json.string(password)),
              #("email", json.string(email)),
            ])
          _ -> json.object([#("id", json.int(0))])
        }
      })
    // nest users json array in a parent json object for proper api response
    json.object([#("users", users)])
  }
  json.to_string_builder(result)
  |> wisp.json_response(200)
}

pub fn get_user_view(req: Request, ctx: Context, id: String) -> Response {
  case int.parse(id) {
    Ok(int_id) -> {
      let id = int_id
      case req.method {
        Get -> get_user(ctx, id)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    }
    Error(_) -> wisp.bad_request()
  }
}

pub fn get_user(ctx: Context, id: Int) -> Response {
  let result = {
    // This is the decoder for the value returned by the 'users' sql query
    let return_type =
      dynamic.tuple4(
        dynamic.int,
        dynamic.string,
        dynamic.string,
        dynamic.string,
      )

    let assert Ok(response) =
      pgo.execute(queries.get_user, ctx.db, [pgo.int(id)], return_type)

    let user = case list.first(response.rows) {
      Ok(#(id, username, password, email)) ->
        json.object([
          #("id", json.int(id)),
          #("username", json.string(username)),
          #("password", json.string(password)),
          #("email", json.string(email)),
        ])
      Error(Nil) -> json.object([#("id", json.int(0))])
    }
  }
  json.to_string_builder(result)
  |> wisp.json_response(200)
}

pub fn create_user(req: Request, ctx: Context) -> Response {
  // Read the JSON from the request body.
  use json <- wisp.require_json(req)
  // Decode the JSON into a User record.
  let assert Ok(user) = decode_user(json)

  let result = {
    let return_type =
      dynamic.tuple4(
        dynamic.int,
        dynamic.string,
        dynamic.string,
        dynamic.string,
      )

    let password_utf = bit_array.from_string(user.password)
    let hashed_password = antigone.hash(antigone.hasher(), password_utf)

    // Save the user to the database.
    let assert Ok(response) =
      pgo.execute(
        queries.create_user,
        ctx.db,
        [
          pgo.text(user.username),
          pgo.text(hashed_password),
          pgo.text(user.email),
        ],
        return_type,
      )

    case list.first(response.rows) {
      Ok(#(id, _, _, _)) -> json.object([#("id", json.int(id))])
      Error(Nil) -> json.object([#("id", json.int(0))])
    }
  }
  json.to_string_builder(result)
  |> wisp.json_response(200)
}

fn decode_user(json: Dynamic) -> Result(User, Nil) {
  let decoder =
    dynamic.decode3(
      User,
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
      dynamic.field("email", dynamic.string),
    )

  decoder(json)
  |> result.nil_error
}
