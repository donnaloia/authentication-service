import wisp.{type Request, type Response}
import app/web.{type Context}
import app/auth/check_tokens
import gleam/json
import app/auth/manage_tokens
import gleam/http.{Get, Post}
import gwt

pub fn refresh_token_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> refresh_token(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn refresh_token(req: Request, ctx: Context) -> Response {
  let #(token_provided, jwt) = check_tokens.get_auth_header(req)

  case token_provided {
    True -> #(token_provided, jwt)
    False -> #(False, "no token provided")
  }

  let user_uuid = manage_tokens.read_refresh_token(ctx, jwt)

  case user_uuid {
    #(True, user_uuid, token_type) -> {
      case token_type {
        "refresh-token" -> {
          let access_token = manage_tokens.create_access_token(ctx, user_uuid)
          json.object([#("access_token", json.string(access_token))])
          |> json.to_string_builder()
          |> wisp.json_response(200)
        }
        _ -> {
          json.object([#("error", json.string("bad request."))])
          |> json.to_string_builder()
          |> wisp.json_response(400)
        }
      }
      let access_token = manage_tokens.create_access_token(ctx, user_uuid)
      json.object([#("access_token", json.string(access_token))])
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    #(False, _, _) -> {
      json.object([#("error", json.string("bad request."))])
      |> json.to_string_builder()
      |> wisp.json_response(400)
    }
  }
}
