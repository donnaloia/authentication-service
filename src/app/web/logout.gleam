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
import gwt.{type Jwt, type Unverified, type Verified}
import birl

pub fn logout_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> logout(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn logout(req: Request, ctx: Context) -> Response {
  todo
  //   // Check http header for access-token
  //   let auth_token = mist.get_header(req, "Authorization")
  //     let token = case auth_token {
  //         Some(token) -> token
  //         None -> return wisp.unauthorized("No token provided")
  //     }
  //   // If access-token is valid, delete it from the database
  //     let result = {
  //         let return_type = dynamic.tuple1(dynamic.int)
  //         let assert Ok(response) =
  //         pgo.execute(
  //             queries.delete_token,
  //             ctx.db,
  //             [pgo.text(token)],
  //             return_type,
  //         )
  //         json.object([#("message", json.string("Successfully logged out"))])
  //     }

  //   let result = {
  //     // This is the decoder for the value returned by the 'users' sql query
  //     let return_type =
  //       dynamic.tuple4(
  //         dynamic.int,
  //         dynamic.string,
  //         dynamic.string,
  //         dynamic.string,
  //       )

  //   let body = json.to_string_builder(result)
  //   wisp.json_response(body, 200)
}
