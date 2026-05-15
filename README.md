# foodorder_mobile

Flutter app for KedaiKlik mobile experience.

## Development mode (Web-first)

This project is configured to make daily development easier on web (Chrome).

1. Install dependencies:
```bash
flutter pub get
```

2. Run on Chrome:
```bash
flutter run -d chrome --dart-define=INITIAL_ROUTE=/landing
```

3. Analyze and test:
```bash
flutter analyze
flutter test
```

## Notes

- Default startup route can be controlled with `INITIAL_ROUTE`.
- Current default (when no define is passed) is `/landing`.
- For iOS validation near release, run periodically with `flutter run -d ios`.
