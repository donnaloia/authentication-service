import app/web.{type Context}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
import gleam/json
import gleam/dict
import gleam/result.{try}
import wisp.{type Request, type Response}
import gleam/pgo

// This request handler is used for requests to `/people`.
//
pub fn all(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> list_users(ctx)
    Post -> create_user(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

// This request handler is used for requests to `/people/:id`.
//
pub fn one(req: Request, ctx: Context, id: String) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> read_user(ctx, id)
    _ -> wisp.method_not_allowed([Get])
  }
}

pub type User {
  User(name: String, password: String, email: String)
}

// This handler returns a list of all the people in the database, in JSON
// format.
//
pub fn list_users(ctx: Context) -> Response {
  let result = {
    // Get all the ids from the database
    //sql query
    let get_users =
      "
  select
    id, username, password, email
  from
    users"

    // This is the decoder for the value returned by the 'users' sql query
    let return_type =
      dynamic.tuple4(
        dynamic.int,
        dynamic.string,
        dynamic.string,
        dynamic.string,
      )

    let assert Ok(response) = pgo.execute(get_users, ctx.db, [], return_type)

    // Convert the ids into a JSON array of objects.
    // return a json array of objects from response.rows
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
  }

  case result {
    // When everything goes well we return a 200 response with the JSON.
    Ok(users) -> wisp.json_response(users, 200)

    // In a later example we will see how to return specific errors to the user
    // depending on what went wrong. For now we will just return a 500 error.
    Error(Nil) -> wisp.internal_server_error()
  }
}

pub fn create_user(req: Request, ctx: Context) -> Response {
  // Read the JSON from the request body.
  use json <- wisp.require_json(req)

  let result = {
    // Decode the JSON into a Person record.
    use user <- try(decode_user(json))

    // Save the person to the database.
    use id <- try(save_to_database(ctx.db, user))

    // Construct a JSON payload with the id of the newly created person.
    Ok(json.to_string_builder(json.object([#("id", json.string(id))])))
  }

  // Return an appropriate response depending on whether everything went well or
  // if there was an error.
  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(Nil) -> wisp.unprocessable_entity()
  }
}

pub fn read_user(ctx: Context, id: String) -> Response {
  let result = {
    // Read the person with the given id from the database.
    use user <- try(read_from_database(ctx.db, id))

    // Construct a JSON payload with the person's details.
    Ok(
      json.to_string_builder(
        json.object([
          #("id", json.string(id)),
          #("username", json.string(user.username)),
          #("password", json.string(user.password)),
          #("email", json.string(user.email)),
        ]),
      ),
    )
  }

  // Return an appropriate response.
  case result {
    Ok(json) -> wisp.json_response(json, 200)
    Error(Nil) -> wisp.not_found()
  }
}

fn decode_person(json: Dynamic) -> Result(User, Nil) {
  let decoder =
    dynamic.decode2(
      User,
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
    )
  let result = decoder(json)

  // In this example we are not going to be reporting specific errors to the
  // user, so we can discard the error and replace it with Nil.
  result
  |> result.nil_error
}
