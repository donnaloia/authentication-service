import wisp.{type Request}
import gleam/http/request.{get_header}
import gleam/string
import gwt.{type Jwt}
import app/web.{type Context}

// Check http header for access-token
pub fn get_auth_header(req: Request) -> #(Bool, String) {
  let auth_token = get_header(req, "Authorization")
  case auth_token {
    Ok(auth_token) -> {
      let token = string.drop_left(auth_token, 8)
      #(True, token)
    }
    Error(_) -> #(False, "No token provided")
  }
}

// verify the token
pub fn verify_auth_header(req: Request, ctx: Context) -> #(Bool, String) {
  let #(token_provided, jwt) = get_auth_header(req)
  // case token_provided = false {
  //     return return false
  let jwt_with_signature = gwt.from_signed_string(jwt, secret_key_base)
}
