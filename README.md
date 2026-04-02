# Mythic Siege

`Mythic Siege` is a Flutter online co-op fantasy shooter for mobile. Players join a room over WebSocket, control heroes with twin virtual joysticks, and defend a cursed citadel against escalating monster waves.

## What is included

- Flutter mobile client with a fantasy-styled HUD, lobby flow, twin-stick controls, and a themed top-down battlefield
- Local 3D character showcases built from in-project low-poly model assets for the paladin, mage, and ranger roster
- Dart WebSocket match server with room-based multiplayer, server-authoritative enemies, bullets, scoring, and respawns
- Android and iOS networking configuration for local multiplayer testing

## Run the multiplayer server

From the project root:

```bash
dart run tool/match_server.dart
```

Optional flags:

```bash
dart run tool/match_server.dart --host=0.0.0.0 --port=8080
```

The server also respects the `PORT` environment variable automatically, which makes it easier to run on Render and similar platforms.

## Run the Flutter app

```bash
flutter pub get
flutter run
```

For a physical Android phone, bake your computer's Wi-Fi server URL into the build so the lobby opens with the right portal by default:

```bash
flutter build apk --debug --dart-define=MYTHIC_SERVER_URL=ws://YOUR_COMPUTER_LAN_IP:8080
```

## Server URL tips

- Android emulator: `ws://10.0.2.2:8080`
- iOS simulator or same machine: `ws://127.0.0.1:8080`
- Physical phone on the same Wi-Fi: `ws://YOUR_COMPUTER_LAN_IP:8080`
- The current lobby can expose a `This PC Wi-Fi` preset when the APK is built with `MYTHIC_SERVER_URL`
- Public Render deployment: `wss://YOUR-RENDER-SERVICE.onrender.com`

## Deploy on Render

This repo now includes a Docker-based Render setup:

- `Dockerfile`
- `render.yaml`
- `server/pubspec.yaml`
- `server/bin/match_server.dart`

Recommended setup:

1. Push this repository to GitHub.
2. In Render, create a new `Blueprint` or `Web Service` from the repo.
3. Deploy the Docker service.
4. Use the resulting `wss://...onrender.com` URL in the mobile app.

Notes:

- Keep Render at `1` instance for now because room state is currently stored in-memory in the server process.
- Free Render instances are fine for testing, but a paid instance is better for live gameplay because it avoids cold starts.

## Controls

- Left joystick: move
- Right joystick: aim and cast attack shots
- Leave button: exit the warband back to the lobby

## Notes

- The current build is a co-op survival siege rather than PvP.
- The server is lightweight and intended for local/dev deployment. For internet play, put it behind a reachable host and secure transport.
