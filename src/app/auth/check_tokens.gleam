import wisp.{type Request}
import gleam/http/request.{get_header}
import gleam/string
import gwt.{type Jwt, type JwtDecodeError, TokenExpired}
import app/web.{type Context}
import gleam/io

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
  // debug statement above returns Ok(Jwt(dict.from_list([#("alg", "HS256"), #("typ", "JWT")]), dict.from_list([#("exp", 1712596662), #("iat", 1712595762), #("jti", "846"), #("sub", "milkman5")])))
  // instead of parsing through this we can just use gwt function to get expiration and subscriber
  case jwt_with_signature {
    Ok(jwt) -> True
    Error(_) -> False
  }
}
