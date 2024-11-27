import cors_builder as cors
import gleam/http

pub fn initiate_cors() {
  cors.new()
  |> cors.allow_origin("*")
  |> cors.allow_all_origins()
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Options)
  |> cors.allow_method(http.Post)
  |> cors.allow_header("Content-Type")
  |> cors.allow_header("Origin")
  |> cors.allow_header("Authorization")
}
