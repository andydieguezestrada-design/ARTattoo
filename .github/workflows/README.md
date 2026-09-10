# ARTattoo Academy CI

The workflow generates `android/local.properties` from the `FLUTTER_ROOT` environment variable before Gradle configuration. This avoids the common `flutter.sdk not set in local.properties` failure in GitHub Actions.

It uses the repository's Gradle wrapper, verifies Gradle 8.14, runs JSON validation, `flutter analyze`, `flutter test`, and finally builds the release APK.
