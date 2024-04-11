import app/web.{type Context}
import gleam/http.{Get, Post}
import wisp.{type Request, type Response}

pub fn logout_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> logout(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn logout(req: Request, ctx: Context) -> Response {
  // Current access-token implementation is optimized for performance
  // so that there are no access-tokens being written to disk.
  // This means that in the current implementation, we cannot 
  // invalidate an access-token.  Logging out can be accomplished
  // from the client side by removing the access-token from local storage
  // which should redirect the user to the login page.
  // api consumers will only lose api access when the access-token expires
  todo
}
