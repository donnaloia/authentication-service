import app/web.{type Context}
import app/api/users
import app/web/login
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["users"] -> users.get_users_view(req, ctx)
    ["users", id] -> users.get_user_view(req, ctx, id)
    ["login"] -> login.login_view(req, ctx)
    // ["logout"] -> users.logout_view(req, ctx)
    // ["refresh-token"] -> users.refresh_token_view(req, ctx)
    _ -> wisp.not_found()
  }
}
