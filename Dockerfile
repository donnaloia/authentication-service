FROM ghcr.io/gleam-lang/gleam:v1.0.0-elixir


WORKDIR /app

# Copy project files
COPY . .

# Install dependencies (replace with actual Gleam build command)
RUN gleam build

# Expose ports
EXPOSE 8080

# Command to run the server
ENTRYPOINT ["gleam", "run"]
