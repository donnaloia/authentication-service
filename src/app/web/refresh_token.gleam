import wisp.{type Request, type Response}
import app/web.{type Context}
import gleam/http.{Get, Post}

pub fn refresh_token_view(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Post -> refresh_token(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn refresh_token(req: Request, ctx: Context) -> Response {
  todo
}
