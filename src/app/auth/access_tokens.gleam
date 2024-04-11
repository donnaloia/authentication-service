import app/web.{type Context}
import gleam/http/request.{get_header}
import gleam/int
import gleam/string
import gwt
import birl
import wisp.{type Request, type Response}

// access-token implementation does not 
// require a r/w to database

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

// verify the access-token
pub fn verify_access_token(req: Request, ctx: Context) -> Bool {
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

// create a new access-token
pub fn create_access_token(ctx: Context, id: String) -> String {
  let fifteen_minutes = birl.to_unix(birl.now()) + 900
  let jti = int.random(1000)
  let jwt =
    gwt.new()
    |> gwt.set_subject(id)
    |> gwt.set_issued_at(birl.to_unix(birl.now()))
    |> gwt.set_expiration(fifteen_minutes)
    |> gwt.set_jwt_id(int.to_string(jti))
    |> gwt.set_issuer("access-token")

  let jwt_with_signature = gwt.to_signed_string(jwt, gwt.HS256, ctx.secret_key)
  jwt_with_signature
}
