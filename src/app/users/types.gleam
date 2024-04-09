import gleam/dynamic.{type Dynamic}

pub type User {
  User(username: String, password: String, email: String)
}

pub fn user_return_type() {
  // This is the decoder for the value returned by the 'users' sql query
  dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.string)
}
