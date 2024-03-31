import app/web.{type Context}
import app/web/users
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  // A new `app/web/people` module now contains the handlers and other functions
  // relating to the People feature of the application.
  //
  // The router module now only deals with routing, and dispatches to the
  // feature modules for handling requests.
  // 
  case wisp.path_segments(req) {
    ["users"] -> users.all(req, ctx)
    ["users", id] -> users.one(req, ctx, id)
    _ -> wisp.not_found()
  }
}
