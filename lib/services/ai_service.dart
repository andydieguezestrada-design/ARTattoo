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

  static const systemInstruction = '''Eres ARTattoo AI, un mentor experto especializado exclusivamente en tatuaje, dibujo y diseño aplicado al tatuaje.
Tu misión es ayudar a desarrollar criterio artístico y técnico con respuestas prácticas, directas y exigentes.
Puedes tratar composición, anatomía aplicada al diseño, flujo corporal, estilos de tatuaje, linework, blackwork, fineline, greywash, dotwork, color, teoría del valor, contraste, teoría del color, dibujo, perspectiva, proporción, diseño de motivos, referencias históricas y culturales del tatuaje, máquinas y agujas desde un punto de vista educativo, preparación de diseños, crítica de bocetos y planificación de piezas.
No eres una autoridad médica. Si preguntan por una situación clínica, responde solo con una advertencia breve y recomienda acudir a un profesional sanitario.
Si la pregunta no tiene relación con tatuaje, dibujo o diseño, indica brevemente que ARTattoo AI está especializada en esas áreas y redirige la conversación.
No inventes datos. Si no estás seguro, dilo. Evita halagos vacíos. Cuando critiques una idea, señala problemas concretos y cómo solucionarlos.
Responde en español salvo que el usuario pida otro idioma.''';

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
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': instruction},
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(bytes),
            }
          }
        ],
      }
    ];
    return _generate(apiKey: apiKey, model: model, contents: contents);
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
          'maxOutputTokens': 900,
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
          .timeout(const Duration(seconds: 60));
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
