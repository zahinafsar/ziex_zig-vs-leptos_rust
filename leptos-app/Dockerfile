FROM rust:1-slim-bookworm AS build

WORKDIR /app

COPY Cargo.toml ./
RUN mkdir src \
    && echo 'fn main() {}' > src/main.rs \
    && cargo build --release \
    && rm -rf src

COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim
COPY --from=build /app/target/release/leptos-app /usr/local/bin/leptos-app

CMD ["leptos-app"]
