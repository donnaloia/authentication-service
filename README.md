
# Auth Service

A modern standalone drop-in auth microservice written in gleam. 

![Erlang](https://img.shields.io/badge/Erlang-white.svg?style=for-the-badge&logo=erlang&logoColor=a90533)![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white)![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)

![example workflow](https://github.com/donnaloia/authentication-service/actions/workflows/docker-build-push.yml/badge.svg)[![GitHub Release](https://img.shields.io/github/release/tterb/PlayMusic.svg?style=flat)]()  

## Features

- REST API endpoints to manage users (see endpoints below)
- password encryption with argon2
- login/logout endpoints suited for SPA's or mobile apps
- full refresh-token and access-token management
- initial testing suggests performance improvements over comparable auth service written in Flask


## Tech Stack

**Containerization:** Docker

**DB:** PostgreSQL

**Server:** Written in Gleam




## Run Locally
docker-compose spins up a postgres instance and the gleam auth service for testing.
To deploy this project locally run:

```bash
  docker-compose build
  docker-compose up
```


## REST API Reference


#### All endpoints require a valid access-token


| HTTP Header | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Bearer <access_token>` | `string` | Your API access token |

#### Get Users

```http
  GET /api/v1/users/
```

```json
{
  "data": [
    {
      "id": "b5b21126-6ca5-4969-9590-7b45edb4a8d0",
      "username": "somereallycoolguy",
      "email": "someone@something.com"
    },
    {
      "id": "30943f82-16b6-437f-ba4e-31516e302462",
      "username": "somelameguy",
      "email": "someone@somewhere.com"
    }
  ]
}
```


#### Get User

```http
  GET /api/v1/users/${id}
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `id`      | `string` | **Required**. Id of user to fetch |

```json
{
  "id": "b5b21126-6ca5-4969-9590-7b45edb4a8d0",
  "username": "nextjs",
  "email": "ben@nextjs.com"
}
```


#### Create User

```http
  POST /api/v1/users/
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `username`      | `string` | **Required**. Username of user to create|
| `password`      | `string` | **Required**. Password of user to create|
| `email`      | `string` | **Required**. Email of user to create|

```json
{
  "id": "30943f82-16b6-437f-ba4e-31516e302462"
}
```

## Login/Logout Endpoints


#### Login

```http
  POST /account/login
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `username`      | `string` | **Required**. username of user logging in |
| `password`      | `string` | **Required**. password of user logging in |

```json
{
  "access_token": 
"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIzMDk0M2Y4Mi0xNmI2LTQzN2YtYmE0ZS0zMTUxNmUzMDI0NjIiLCJqdGkiOiIzODkiLCJpc3MiOiJhY2Nlc3MtdG9rZW4iLCJpYXQiOjE3MzQ5OTQyOTQsImV4cCI6MTczNDk5NTE5NH0.ghSF8VsdFKK9JfJCKFDaAZF5l_s4uFBeRkA8BmI1mZ8",
  "expires_at": "1734995194",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIzMDk0M2Y4Mi0xNmI2LTQzN2YtYmE0ZS0zMTUxNmUzMDI0NjIiLCJqdGkiOiI3MDAiLCJpc3MiOiJyZWZyZXNoLXRva2VuIiwiaWF0IjoxNzM0OTkyMTcxLCJleHAiOjE3Mzc2MjA0NTl9.YW1R6AmLj2dAleczLMnTTDF9oOaIprk-oeIIlejchlA"
}
```

#### Logout

```http
  POST /account/logout
```

| HTTP Header | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Bearer <access_token>` | `string` | Your API access token |

#### Refresh Token

```http
  POST /refresh-token
```

| HTTP Header | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Bearer <refresh_token>` | `string` | Your API refresh token |


## Todo

- refactor views (still learning Gleam)
- api pagination
- api docs server
- add test coverage
- token caching
- CLI admin tool
