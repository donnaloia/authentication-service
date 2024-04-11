pub const initialize_users_table = "
CREATE TABLE IF NOT EXISTS users (
    id uuid PRIMARY KEY,
    username VARCHAR(255),
    password VARCHAR(255),
    email VARCHAR(255)
)"

pub const initialize_refresh_tokens_table = "
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id uuid,
  token VARCHAR(255),
  FOREIGN KEY (user_id) REFERENCES users(id)
)"
