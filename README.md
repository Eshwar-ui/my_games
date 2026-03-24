# My Games

A Flutter collection of classic and arcade games with a dark **neon** look: cyan and magenta accents, glow-style borders, and the **Orbitron** font.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
- Dart SDK **^3.8.1** (as specified in `pubspec.yaml`)

Check your setup:

```bash
flutter doctor
```

## Getting started

1. **Clone** this repository (replace the URL with yours):

   ```bash
   git clone https://github.com/<your-username>/my_games.git
   cd my_games
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run** on a connected device or emulator:

   ```bash
   flutter run
   ```

   Examples for specific targets:

   ```bash
   flutter run -d windows
   flutter run -d chrome
   ```

## Games

| Game | Notes |
|------|--------|
| **Tic-Tac-Toe** | Two-player on one device; win/draw detection. |
| **Brick Breaker** | Paddle and ball; **persistent high score** (`shared_preferences`). |
| **Tetris** | Line clears and controls; **persistent high score**. |
| **Snake** | Eat food, grow, avoid walls/self; **persistent high score**. |
| **2048** | Merge tiles; **persistent high score**. |
| **Flappy Bird** | Tap to fly through gaps; high score is **session only** (not saved after exit). |
| **Space War** | Shoot enemies Space Invaders–style; score shown in-game. |

## Features

- **Main menu** listing all games with neon-styled tiles.
- **Best scores** saved across restarts for Brick Breaker, Tetris, Snake, and 2048.
- **Cross-platform**: Android, iOS, Web, Windows, macOS, and Linux (standard Flutter targets).
- **App icon & splash**: configured via `flutter_launcher_icons` and `flutter_native_splash` (see `pubspec.yaml`).

## Project layout

- `lib/main.dart` — app theme and game launcher.
- `lib/games/` — one Dart file per game.

## Development

```bash
flutter analyze
flutter test
```

Regenerate launcher icons or splash after changing `pubspec.yaml` assets/config:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Screenshots

Add images here (for example `docs/screenshots/`) to show the menu and each game.

## Contributing

Issues and pull requests are welcome. If you publish the repo publicly, consider adding a **LICENSE** file so others know how they may use the code.
