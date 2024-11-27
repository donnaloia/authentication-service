import app/api/users
import app/web.{type Context}
import app/web/login
import app/web/logout
import app/web/refresh_token
import cors_builder as cors
import middleware/cors_protection
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)
  use req <- cors.wisp_middleware(req, cors_protection.initiate_cors())

  case wisp.path_segments(req) {
    ["users"] -> users.get_users_view(req, ctx)
    ["users", uuid] -> users.get_user_view(req, ctx, uuid)
    ["login"] -> login.login_view(req, ctx)
    ["logout"] -> logout.logout_view(req, ctx)
    ["refresh-token"] -> refresh_token.refresh_token_view(req, ctx)
    _ -> wisp.not_found()
  }
}
