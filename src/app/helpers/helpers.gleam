import app/auth/access_tokens

pub fn is_verified(req: Request) -> Bool {
    let authorized = access_tokens.verify_access_token(req, ctx)
    case authorized {
        Ok(_) -> {True

                 }
        Err(_) -> False
    }
}

pub fn get_pagination(req: Request, auth: Bool) -> (page: Int, offset: Int) {
    case auth {
        True -> { let page = req.query.get("page").unwrap_or("1").parse::<i32>().unwrap_or(1);
                  let offset = (page - 1) * 10
                  (page, offset) }
        False -> (0, 0)
    }}
}

// NOTE:  the functions below should be moved to the users/ directory
// keeping them here in one place for now for development, as all these
// function calls will be chained

pub fn get_user_from_db(req: Request, auth: Bool, page: Int, offset: Int) -> #(String, String, String, String) {
    let assert Ok(db_response) =
        pgo.execute(
          queries.get_user,
          ctx.db,
          [pgo.text(id)],
          types.user_return_type(),
        )
    case list.first(db_response.rows) {
        Ok(#(id, username, password, email)) -> #(id, username, password, email)
        Error(_) -> #("error", json.string("The requested user could not be found."))
    }

pub fn construct_json(user: #(String, String, String, String)) -> Json {
    let #(uuid, username, password, email) = user
    json.object([
        #("id", json.string(uuid)),
        #("username", json.string(username)),
        #("password", json.string(password)),
        #("email", json.string(email)),
        ])
}