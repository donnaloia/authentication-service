import gleam/erlang/process
import mist
import wisp
import app/router
import app/web
import app/sql/migrations
import app/users/types
import gleam/pgo
import gleam/option
import gleam/erlang/os
import gleam/result

pub const data_directory = "tmp/data"

pub fn main() {
  wisp.configure_logger()
  let secret_key = load_application_secret()
  let db_user = load_postgres_user()
  let db_password = load_postgres_password()
  let db_auth_database = load_postgres_auth_database()
  let db_host = load_postgres_host()

  // A database creation is created here, when the program starts.
  // This connection is used by all requests.
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        user: db_user,
        password: option.Some(db_password),
        host: db_host,
        database: db_auth_database,
        port: 5432,
        pool_size: 15,
      ),
    )

  let assert Ok(_) =
    pgo.execute(
      migrations.initialize_users_table,
      db,
      [],
      types.delete_user_return_type(),
    )
  let assert Ok(_) =
    pgo.execute(
      migrations.initialize_refresh_tokens_table,
      db,
      [],
      types.delete_user_return_type(),
    )

  let context = web.Context(db: db, secret_key: secret_key)

  // The handle_request function is partially applied with the context to make
  // the request handler function that only takes a request.
  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http
  process.sleep_forever()
}

fn load_application_secret() -> String {
  os.get_env("SECRET_KEY")
  |> result.unwrap("APPLICATION_SECRET is not set.")
}

fn load_postgres_user() -> String {
  os.get_env("DB_USER")
  |> result.unwrap("POSTGRES_USER is not set.")
}

fn load_postgres_password() -> String {
  os.get_env("DB_PASSWORD")
  |> result.unwrap("POSTGRES_PASSWORD is not set.")
}

fn load_postgres_auth_database() -> String {
  os.get_env("DB_DATABASE")
  |> result.unwrap("POSTGRES_AUTH_DATABASE is not set.")
}

fn load_postgres_host() -> String {
  os.get_env("DB_HOST")
  |> result.unwrap("DB_HOST is not set.")
}
