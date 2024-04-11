import gwt
import gleam/dynamic
import app/web.{type Context}
import app/sql/queries
import gleam/int
import gleam/pgo
import gleam/list
import app/users/types
import birl

// get id, user_uuid and token from refresh token
pub fn get_refresh_token(ctx: Context, user_uuid: String) -> String {
  let assert Ok(db_response) =
    pgo.execute(
      queries.get_refresh_token_by_user_id,
      ctx.db,
      [pgo.text(user_uuid)],
      types.refresh_token_return_type(),
    )
  case list.first(db_response.rows) {
    Ok(#(_id, _user_id, token)) -> token
    Error(_) -> "no token found"
  }
}

// create new refresh token
pub fn create_refresh_token(ctx: Context, user_uuid: String) -> String {
  let one_month = birl.to_unix(birl.now()) + 2_628_288
  let jti = int.random(1000)
  let jwt =
    gwt.new()
    |> gwt.set_subject(user_uuid)
    |> gwt.set_issued_at(birl.to_unix(birl.now()))
    |> gwt.set_expiration(one_month)
    |> gwt.set_jwt_id(int.to_string(jti))
    |> gwt.set_issuer("refresh-token")

  let return_type = dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string)
  let jwt_with_signature = gwt.to_signed_string(jwt, gwt.HS256, ctx.secret_key)

  // saves refresh-token to the database.
  let assert Ok(_db_response) =
    pgo.execute(
      queries.create_refresh_token,
      ctx.db,
      [pgo.text(user_uuid), pgo.text(jwt_with_signature)],
      return_type,
    )

  jwt_with_signature
}

// returns the user_uuid from refresh token
pub fn get_user_from_refresh_token(
  ctx: Context,
  jwt: String,
) -> #(Bool, String, String) {
  let jwt = gwt.from_signed_string(jwt, ctx.secret_key)
  case jwt {
    Ok(jwt) -> {
      let uuid = gwt.get_subject(jwt)
      case uuid {
        Ok(uuid) -> {
          let assert Ok(token_type) = gwt.get_issuer(jwt)
          case token_type {
            "refresh-token" -> {
              #(True, uuid, "token_type")
            }
            _ -> #(False, "invalid token type", token_type)
          }
        }
        Error(_) -> #(False, "error", "error")
      }
    }
    Error(_) -> #(False, "error", "error")
  }
}
