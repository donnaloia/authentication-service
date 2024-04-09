
# Auth Service

A modern standalone drop-in auth microservice written in gleam.


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
| `bearer <access_token>` | `string` | Your API access token |

#### Get Users

```http
  GET /api/v1/users/
```


#### Get User

```http
  GET /api/v1/users/${id}
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `id`      | `string` | **Required**. Id of user to fetch |


#### Create User

```http
  POST /api/v1/users/
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `username`      | `string` | **Required**. Username of user to create|
| `password`      | `string` | **Required**. Password of user to create|
| `email`      | `string` | **Required**. Email of user to create|


## Login/Logout Endpoints


#### Login

```http
  POST /account/login
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `username`      | `string` | **Required**. username of user logging in |
| `password`      | `string` | **Required**. password of user logging in |

#### Logout

```http
  POST /account/logout
```

| HTTP Header | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `bearer <access_token>` | `string` | Your API access token |


```http
  POST /refresh-token
```



## Todo

- api doc server
- refactor views (still learning Gleam)
- add test coverage
- nosql support (for token storage)
- CLI admin tool

