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
import app/auth/check_tokens
import gleam/io
import app/users/types

pub fn get_users_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> list_users(req, ctx)
    Post -> create_user(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn list_users(req: Request, ctx: Context) -> Response {
  let authorized = check_tokens.verify_auth_header(req, ctx)
  case authorized {
    True -> {
      let assert Ok(response) =
        pgo.execute(queries.get_users, ctx.db, [], types.user_return_type())

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
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    False -> {
      json.object([#("error", json.string("Unauthorized request."))])
      |> json.to_string_builder()
      |> wisp.json_response(401)
    }
  }
}

pub fn get_user_view(req: Request, ctx: Context, id: String) -> Response {
  case int.parse(id) {
    Ok(int_id) -> {
      let id = int_id
      case req.method {
        Get -> get_user(req, ctx, id)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    }
    Error(_) -> wisp.bad_request()
  }
}

pub fn get_user(req: Request, ctx: Context, id: Int) -> Response {
  let authorized = check_tokens.verify_auth_header(req, ctx)
  case authorized {
    True -> {
      let assert Ok(response) =
        pgo.execute(
          queries.get_user,
          ctx.db,
          [pgo.int(id)],
          types.user_return_type(),
        )

      case list.first(response.rows) {
        Ok(#(id, username, password, email)) ->
          json.object([
            #("id", json.int(id)),
            #("username", json.string(username)),
            #("password", json.string(password)),
            #("email", json.string(email)),
          ])
          // Return the user as a JSON object.
          |> json.to_string_builder()
          |> wisp.json_response(200)

        Error(Nil) ->
          json.object([
            #("error", json.string("The requested user could not be found.")),
          ])
          // Return a 404 Not Found response.
          |> json.to_string_builder()
          |> wisp.json_response(404)
      }
    }
    False -> {
      json.object([#("error", json.string("Unauthorized request."))])
      |> json.to_string_builder()
      |> wisp.json_response(401)
    }
  }
}

pub fn create_user(req: Request, ctx: Context) -> Response {
  // Read the JSON from the request body.
  use json <- wisp.require_json(req)
  // Decode the JSON into a User record.
  let assert Ok(user) = decode_user(json)

  let password_utf = bit_array.from_string(user.password)
  let hashed_password = antigone.hash(antigone.hasher(), password_utf)

  let assert Ok(response) =
    pgo.execute(
      queries.get_user_by_username,
      ctx.db,
      [pgo.text(user.username)],
      types.user_return_type(),
    )

  case list.first(response.rows) {
    Ok(#(_id, _username, _password, _email)) -> {
      // A user with the same username already exists.
      json.object([#("error", json.string("Username already exists."))])
      |> json.to_string_builder()
      |> wisp.json_response(409)
    }
    Error(Nil) -> {
      // No user with username exists
      let assert Ok(response) =
        pgo.execute(
          queries.create_user,
          ctx.db,
          [
            pgo.text(user.username),
            pgo.text(hashed_password),
            pgo.text(user.email),
          ],
          types.user_return_type(),
        )

      case list.first(response.rows) {
        Ok(#(id, _, _, _)) -> {
          json.object([#("id", json.int(id))])
          |> json.to_string_builder()
          |> wisp.json_response(201)
        }
        Error(Nil) -> {
          json.object([#("error", json.string("Invalid request."))])
          |> json.to_string_builder()
          |> wisp.json_response(400)
        }
      }
    }
  }
}

fn decode_user(json: Dynamic) -> Result(types.User, Nil) {
  let decoder =
    dynamic.decode3(
      types.User,
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
      dynamic.field("email", dynamic.string),
    )

  decoder(json)
  |> result.nil_error
}
