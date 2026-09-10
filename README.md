# ARTattoo Academy PRO 1.2.0

Aplicación Flutter centrada en tatuaje, dibujo y diseño: biblioteca técnica, exploración de estilos y un mentor de IA online con Gemini.

## Incluye

- Enciclopedia técnica de tatuaje.
- Style Explorer.
- ARTattoo AI especializado exclusivamente en tatuaje, dibujo y diseño.
- Chat de texto con contexto conversacional.
- Análisis de referencias de imagen con Gemini.
- Límite local de **100 análisis de imágenes por día**.
- Ajustes para API key y selección de modelo Gemini.
- Prueba de conexión con Gemini.
- Tema claro/oscuro/automático y control de animaciones.
- Internet para servicios online.
- Galería para seleccionar imágenes mediante `image_picker`.
- Pipeline GitHub Actions preparado para compilar APK release.

Los módulos de ejercicios, clases/lecciones y progreso fueron retirados de la navegación y de la lógica de la aplicación.

## IA y cuota

Modelo recomendado: `gemini-3.6-flash`.

La API gratuita de Gemini está sujeta a cuotas y límites de Google; ARTattoo no promete uso ilimitado. El límite de 100 imágenes/día es un control local adicional para evitar un consumo accidental elevado.

La API key se guarda localmente en el dispositivo. Para distribuir la APK públicamente, la arquitectura más segura es usar un backend propio y mantener la clave en el servidor.

## Ejecutar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## GitHub Actions

Workflow: `.github/workflows/build-apk.yml`

Pipeline:

```text
Checkout v5 → Java 17 → Flutter stable → pub get → JSON validation → analyze → test → build APK → artifact
```

El workflow usa `actions/checkout@v5` y `actions/setup-java@v5`.

## Android

Se mantiene permiso de Internet para Gemini y servicios online. `image_picker` gestiona la selección de imágenes desde la galería mediante los mecanismos nativos de Android.

## Seguridad

Una API key incluida en una APK puede ser extraída. Para una versión pública o comercial, usar un backend propio con límites por usuario y control de abuso.
