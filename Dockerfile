FROM ghcr.io/gleam-lang/gleam:v1.0.0-elixir

WORKDIR /app

# Copy project files
COPY . .

# Install dependencies
# argon2 gleam library requires elixir, so this installs hex
# and then builds the gleam project after
RUN mix local.hex --force 
RUN gleam build


# Expose ports
EXPOSE 8080

# Command to run the server
ENTRYPOINT ["gleam", "run"]
