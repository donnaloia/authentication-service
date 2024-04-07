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

pub const get_user_by_username = "
  select
    id, username, password, email
  from
    users
  where
    username = $1"

pub const create_user = "
  INSERT INTO users
    (username, password, email)
  VALUES
    ($1, $2, $3)
  RETURNING
    *"

pub const create_access_token = "
    INSERT INTO access_tokens
      (user_id, token)
    VALUES
      ($1, $2)
    RETURNING
      *"

pub const delete_access_token = "
  DELETE FROM
    access_tokens
  WHERE
    token = $1"

pub const delete_access_token_by_user = "
  DELETE FROM
    access_tokens
  WHERE
    user_id = $1"
