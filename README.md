# gleam auth server
modern auth server written in Gleam.

# Features
* REST API endpoints to manage users (see endpoints below)
* password encryption with argon2
* login/logout endpoints suited for SPA's or mobile apps
* endpoint for access-token management

# How to run it
docker-compose spins up a postgres instance and gleam auth service for testing.

```sh
docker-compose build
docker-compose up
```

# REST API endpoints
```json
GET User/s
GET /api/v1/users
GET /api/v1/users/:id

Create User
POST localhost:8000/users
```

# Auth endpoints
```json
GET /account/login
GET /account/logout
GET /account/refresh-token

```

# Todo
* refactor a lot of the logic around creating json objects (still learning gleam)
* add tests
* support for nosql

