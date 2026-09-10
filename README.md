# ARTattoo Academy v1.0

Academia educativa móvil, local y ligera para el aprendizaje estructurado del arte del tatuaje.

## Características

- Historia y fundamentos.
- Líneas, sombreado y relleno.
- Piel, higiene y cicatrización.
- Máquinas, agujas, stroke y voltaje orientativo.
- Dibujo y composición.
- Anatomía y adaptación al cuerpo.
- Style Explorer con 19 estilos.
- Prácticas progresivas.
- Dark Mode y Light Mode.
- Sin cuentas.
- Sin backend.
- Sin IA.
- Sin funciones online obligatorias.

## Stack

- Flutter 3.47.2.
- Material 3.
- Android SDK 36.
- Java 17 en CI.
- Gradle 8.14.
- Android Gradle Plugin 8.12.1.
- Kotlin Gradle Plugin 2.2.20.
- shared_preferences 2.5.5.

## Ejecutar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Compilar APK

```bash
flutter build apk --release
```

Salida:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions

Workflow: `.github/workflows/build-apk.yml`

Pipeline:

```text
Checkout → Java 17 → Flutter 3.47.2 → pub get → analyze → test → build APK → SHA256 → artifact
```

Se ejecuta con push, pull request y `workflow_dispatch`.

## Contenido

```text
assets/data/
├── styles.json
└── practices.json
```

Las imágenes tienen carpetas preparadas en `assets/images/`. La v1.0 no depende de URLs externas.


Se guarda localmente mediante `shared_preferences`. No se guarda información sensible.

## Android

No se declaran permisos sensibles innecesarios. El release de CI usa firma debug únicamente para generar un APK instalable de prueba. Antes de publicar, sustituir por una firma release propia.

## Seguridad y contenido sanitario

El material sobre piel, higiene y cicatrización es educativo y no sustituye formación profesional, normativa sanitaria ni evaluación médica. La app no realiza diagnósticos.

Los conceptos de stroke y voltaje son orientativos y no representan configuraciones universales.

## Sin IA

ARTattoo Academy v1.0 no contiene chatbot, generación de imágenes por IA, reconocimiento de imágenes, Machine Learning, APIs de IA ni backend de IA.

## Futuro

La arquitectura queda preparada para futuras ampliaciones como quiz, favoritos, buscador, certificados, diario, galería, cursos, usuarios, premium o IA. No forman parte de v1.0.

## GitHub Actions CI

The CI workflow creates `android/local.properties` before invoking Gradle because Flutter's Android `settings.gradle` reads `flutter.sdk` from that file during Gradle configuration. The file is generated only in CI and is ignored by Git.

The workflow also generates the Gradle wrapper after `local.properties` exists, then runs `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --release`.
