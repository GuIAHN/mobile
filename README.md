# guiautomotriz_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android release

Release builds default to the production environment so they never point to
the Android emulator host (`10.0.2.2`). For a client delivery, keep the API URL
explicit in the build command:

```bash
flutter build apk --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://guia-api-test.onrender.com/api \
  --dart-define=CARTO_BASEMAP_API_KEY=YOUR_CARTO_BASEMAP_API_KEY
```

After building, verify the artifact before sharing it:

```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk \
  lib/arm64-v8a/libapp.so | strings | rg guia-api-test.onrender.com
```
