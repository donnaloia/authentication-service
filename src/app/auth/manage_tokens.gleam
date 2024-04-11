import app/web.{type Context}
import app/sql/queries
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/json
import gleam/pgo
import gwt
import birl
import wisp.{type Request, type Response}
import gleam/io

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

  // Save refresh-token to the database.
  let assert Ok(_) =
    pgo.execute(
      queries.create_refresh_token,
      ctx.db,
      [pgo.text(user_uuid), pgo.text(jwt_with_signature)],
      return_type,
    )

  jwt_with_signature
}

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
  // note: access-tokens are not saved to the database
  jwt_with_signature
}

pub fn read_refresh_token(ctx: Context, jwt: String) -> #(Bool, String, String) {
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
