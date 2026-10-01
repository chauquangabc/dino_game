# Repository Guidelines

## Project Structure & Module Organization

This repository contains a cross-platform Flutter game. Application code lives in `lib/`; `main.dart` is the entry point. Shared infrastructure is grouped under `lib/core/` (`config`, `di`, `network`, `router`, `storage`, and responsive UI helpers). Game areas are organized by feature under `lib/feature/<feature>/`, typically split into `data`, `domain`, and `presentation` layers. Current features include home, profile, ranking, store, farm, and lucky wheel.

Tests live in `test/`, with reusable fakes in `test/support/`. Static artwork is grouped by feature in `assets/` and must also be declared in `pubspec.yaml`. Platform runners are in `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`. Consult `GAME-RULES.md` before changing gameplay behavior and `docs/` for implementation notes.

## Build, Test, and Development Commands

- `flutter pub get` installs dependencies from `pubspec.lock`.
- `flutter run` launches the app on a selected device; use `flutter devices` to list targets.
- `flutter analyze` checks code against `flutter_lints` and `analysis_options.yaml`.
- `dart format lib test` applies standard Dart formatting.
- `flutter test` runs all unit and widget tests.
- `flutter build apk --debug` produces a local Android debug build.

Run analysis and tests before submitting a change.

## Coding Style & Naming Conventions

Use Dart's standard two-space indentation and let `dart format` determine line wrapping. Name files and directories in `snake_case`, classes and enums in `UpperCamelCase`, and variables and methods in `lowerCamelCase`. Keep feature-specific code inside its feature directory; move code to `core` only when multiple features genuinely share it. Prefer small widgets, immutable models, `const` constructors, and package imports such as `package:dino/...`.

## Testing Guidelines

Tests use `flutter_test`. Name files `<subject>_test.dart`; use `test()` for domain/repository behavior and `testWidgets()` for UI behavior. Cover persistence boundaries, game-rule edge cases, and responsive layouts when modifying those areas. Use `MemorySecureStorage` from `test/support/` instead of device storage. Run a focused test with `flutter test test/profile_repository_test.dart`.

## Commit & Pull Request Guidelines

History uses short, feature-oriented subjects such as `Feat : profile` and `UI store`. Follow that concise imperative style, but state the affected area clearly (for example, `Fix: store wallet persistence`). Keep commits focused. Pull requests should summarize behavior changes, list verification commands, link relevant issues, and include screenshots or recordings for UI or asset changes. Call out changes to storage formats, dependencies, or game rules explicitly.
