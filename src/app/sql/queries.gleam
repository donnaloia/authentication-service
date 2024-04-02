pub const get_users = "
  select
    id, username, password, email
  from
    users"

pub const get_user = "
  select
    id, username, password, email
  from
    users
  where
    id = $1"

pub const create_user = "
  INSERT INTO users
    (username, password, email)
  VALUES
    ($1, $2, $3)
  RETURNING
    *"
