import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class AiServiceException implements Exception {
  const AiServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://generativelanguage.googleapis.com/v1beta/models';

  static const systemInstruction = '''Eres ARTattoo AI, un mentor profesional especializado EXCLUSIVAMENTE en tatuaje, dibujo y diseño aplicado al tatuaje.

Tu objetivo no es dar respuestas superficiales. Debes razonar, observar y explicar con profundidad suficiente para que un tatuador pueda tomar decisiones reales sobre un diseño.

REGLAS DE RESPUESTA:
- Responde de forma desarrollada, argumentada y específica por defecto. No reduzcas una respuesta útil a dos o tres frases genéricas.
- Explica el PORQUÉ de tus conclusiones y, cuando sea posible, el CÓMO aplicarlas.
- Prioriza observaciones concretas sobre halagos o frases motivacionales.
- Si analizas un diseño, separa claramente fortalezas, problemas, riesgos y soluciones.
- Si analizas una imagen, describe solamente lo que realmente puedas observar. No inventes detalles ocultos ni supongas elementos que no son visibles.
- Cuando la imagen tenga valor para tatuaje, analiza composición, jerarquía visual, flujo corporal, anatomía y proporciones si aplica, silueta, masas de negro, negativo, líneas principales, detalles internos, valores, contraste, profundidad, legibilidad a distancia y envejecimiento visual.
- Para una posible plantilla/stencil, analiza qué líneas deberían conservarse, cuáles sobran, qué zonas necesitan simplificación, dónde puede cerrarse el negro y dónde conviene proteger el negativo.
- Si el usuario pide una crítica, sé directo. Señala problemas concretos y propón correcciones concretas.
- Si faltan datos importantes, indícalo y trabaja con lo que sí es visible.
- Usa títulos, listas y pasos cuando mejoren la claridad.
- Para análisis visuales importantes, intenta cubrir: 1) lectura general, 2) composición y flujo, 3) anatomía/proporción, 4) valores y contraste, 5) línea y detalle, 6) negativo y masas negras, 7) adaptación al tatuaje, 8) problemas previsibles, 9) recomendaciones prioritarias y 10) conclusión profesional.
- No conviertas automáticamente una imagen en una instrucción para crear otra imagen. Tu función aquí es ANALIZAR, CRITICAR y EXPLICAR.
- Puedes tratar blackwork, fineline, greywash, dotwork, realism, neo-traditional, ornamental, Japanese, biomechanical, surrealism y otros estilos de tatuaje; composición, perspectiva, proporción, teoría del color, teoría del valor, anatomía aplicada al diseño, agujas y máquinas desde un punto de vista educativo, preparación de diseños y planificación de piezas.
- Si preguntan por una situación clínica o una complicación médica, no diagnostiques: da una advertencia breve y recomienda consultar a un profesional sanitario.
- Si la pregunta no tiene relación con tatuaje, dibujo o diseño, indica brevemente que ARTattoo AI está especializada en esas áreas y redirige la conversación.
- No inventes datos. Si no estás seguro, dilo.
- Responde en español salvo que el usuario pida otro idioma.''';

  Future<String> chat({
    required String apiKey,
    required String model,
    required List<Map<String, String>> history,
  }) async {
    final contents = history
        .map((m) => {
              'role': m['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m['content'] ?? ''}
              ],
            })
        .toList();
    return _generate(apiKey: apiKey, model: model, contents: contents);
  }

  Future<String> analyzeImage({
    required String apiKey,
    required String model,
    required Uint8List bytes,
    required String mimeType,
    required String instruction,
  }) async {
    // Google recomienda combinar la imagen y la instrucción como un prompt multimodal.
    // Colocamos la imagen primero y la orden del usuario después para que la orden
    // quede explícitamente asociada a la imagen que debe analizar.
    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(bytes),
            }
          },
          {'text': instruction},
        ],
      }
    ];
    return _generate(
      apiKey: apiKey,
      model: model,
      contents: contents,
      maxOutputTokens: 2400,
    );
  }

  Future<bool> testConnection({required String apiKey, required String model}) async {
    final response = await _post(
      apiKey: apiKey,
      model: model,
      body: {
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': 'Responde solamente: ARTattoo AI conectada.'}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 32},
      },
    );
    return _extractText(response).isNotEmpty;
  }

  Future<String> _generate({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> contents,
    int maxOutputTokens = 2400,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const AiServiceException('Configura tu API key de Gemini en Ajustes > IA y servicios online.');
    }
    final response = await _post(
      apiKey: apiKey.trim(),
      model: model,
      body: {
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': contents,
        'generationConfig': {
          'maxOutputTokens': maxOutputTokens,
        },
      },
    );
    final text = _extractText(response);
    if (text.isEmpty) {
      throw const AiServiceException('Gemini no devolvió contenido. Inténtalo de nuevo.');
    }
    return text;
  }

  Future<Map<String, dynamic>> _post({
    required String apiKey,
    required String model,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_base/${Uri.encodeComponent(model)}:generateContent?key=${Uri.encodeQueryComponent(apiKey)}');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw const AiServiceException('No se pudo conectar con Gemini. Comprueba Internet e inténtalo de nuevo.');
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      final message = error is Map ? error['message']?.toString() : null;
      if (response.statusCode == 429) {
        throw AiServiceException('Límite temporal de Gemini alcanzado. Espera un poco y vuelve a intentarlo.');
      }
      if (response.statusCode == 400 || response.statusCode == 403) {
        throw AiServiceException(message ?? 'La API key o el modelo de Gemini no son válidos.');
      }
      throw AiServiceException(message ?? 'Gemini respondió con el error ${response.statusCode}.');
    }
    return data;
  }

  String _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final content = candidates.first['content'];
    if (content is! Map) return '';
    final parts = content['parts'];
    if (parts is! List) return '';
    return parts
        .whereType<Map>()
        .map((p) => p['text']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n');
  }

  void dispose() => _client.close();
}
