FROM dart:stable AS build

WORKDIR /app

COPY server/pubspec.yaml ./server/pubspec.yaml
RUN dart pub get --directory server

COPY tool ./tool
COPY server ./server
RUN dart pub get --directory server
RUN dart compile exe server/bin/match_server.dart -o /app/bin/mythic_siege_server

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/bin/mythic_siege_server /app/mythic_siege_server

ENV PORT=8080
EXPOSE 8080

CMD ["/bin/sh", "-c", "/app/mythic_siege_server --host=0.0.0.0 --port=${PORT}"]
