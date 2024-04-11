import gleam/dynamic

pub type User {
  User(username: String, password: String, email: String)
}

pub fn user_return_type() {
  // This is the decoder for the value returned by the 'users' sql query
  dynamic.tuple4(dynamic.string, dynamic.string, dynamic.string, dynamic.string)
}

pub fn delete_user_return_type() {
  dynamic.dynamic
}

pub fn refresh_token_return_type() {
  dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string)
}
