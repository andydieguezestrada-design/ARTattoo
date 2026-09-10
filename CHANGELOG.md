# Changelog

## 1.2.2
- Migrado el modelo predeterminado de Gemini 2.5 Flash a Gemini 3.6 Flash por compatibilidad con cuentas nuevas.
- Eliminados del selector los modelos 2.5 que pueden no estar disponibles para usuarios nuevos.
- Ajustada la configuración de generación para evitar parámetros de muestreo obsoletos.

## 1.2.1
- Límite preventivo local de 30 mensajes de chat Gemini por día.
- Contador separado de chat e imágenes en ARTattoo AI.
- El mensaje de chat solo se contabiliza cuando Gemini responde correctamente.
- Reinicio automático de ambos contadores cada día.
- Reducción del máximo de salida del chat a 900 tokens para moderar consumo.

## 1.2.0
- Integración nativa con Gemini API.
- Chat especializado exclusivamente en tatuaje, dibujo y diseño.
- Análisis de referencias de imagen con Gemini.
- Límite local de 100 análisis de imágenes por día.
- Ajustes de API key, modelo y prueba de conexión.
- Eliminación de módulos de ejercicios, clases/lecciones y progreso de la navegación y lógica.
- Eliminación de la dependencia WebView/Puter.
- CI actualizado a `actions/checkout@v5` y `actions/setup-java@v5`.

## 1.1.1
- Corrección de referencia inexistente a `ProgressService` que hacía fallar `flutter analyze` en GitHub Actions.
