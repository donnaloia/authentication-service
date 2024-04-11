import wisp.{type Request}
import gleam/http/request.{get_header}
import gleam/string
import gwt.{type Jwt, type JwtDecodeError, TokenExpired}
import app/web.{type Context}
import app/sql/queries
import gleam/io
import gleam/pgo
import gleam/list
import app/users/types

// Check http header for access-token
pub fn get_auth_header(req: Request) -> #(Bool, String) {
  let auth_token = get_header(req, "Authorization")
  case auth_token {
    Ok(auth_token) -> {
      let token = string.drop_left(auth_token, 7)
      #(True, token)
    }
    Error(_) -> #(False, "mi")
  }
}

// verify the token
pub fn verify_auth_header(req: Request, ctx: Context) -> Bool {
  let #(token_provided, jwt) = get_auth_header(req)
  case token_provided {
    True -> #(token_provided, jwt)
    False -> #(False, "no token provided")
  }

  let jwt_with_signature = gwt.from_signed_string(jwt, ctx.secret_key)
  case jwt_with_signature {
    Ok(jwt) -> {
      let assert Ok(token_type) = gwt.get_issuer(jwt)
      case token_type {
        "access-token" -> True
        _ -> False
      }
    }
    Error(_) -> False
  }
}

// verify the token
pub fn get_refresh_token(ctx: Context, user_uuid: String) -> String {
  let assert Ok(response) =
    pgo.execute(
      queries.get_refresh_token_by_user_id,
      ctx.db,
      [pgo.text(user_uuid)],
      types.refresh_token_return_type(),
    )
  case list.first(response.rows) {
    Ok(#(_id, _user_id, token)) -> token
    Error(_) -> "no token found"
  }
}
