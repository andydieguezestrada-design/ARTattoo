import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';
import '../services/chat_quota_service.dart';
import '../services/image_quota_service.dart';
import '../services/settings_service.dart';

class AiTattooScreen extends StatefulWidget {
  const AiTattooScreen({super.key});

  @override
  State<AiTattooScreen> createState() => _AiTattooScreenState();
}

class _AiTattooScreenState extends State<AiTattooScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AiService _service = AiService();
  final List<_Message> _messages = <_Message>[];

  Uint8List? _attachedBytes;
  String? _attachedMime;
  String? _attachedName;

  bool _busy = false;
  int _imageUsed = 0;
  int _chatUsed = 0;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _refreshQuota();
  }

  Future<void> _refreshQuota() async {
    final imageValue = await ImageQuotaService.usedToday();
    final chatValue = await ChatQuotaService.usedToday();
    if (mounted) {
      setState(() {
        _imageUsed = imageValue;
        _chatUsed = chatValue;
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _intro.dispose();
    _service.dispose();
    super.dispose();
  }

  /// Adjunta una imagen al mensaje. No se envía todavía: el usuario puede
  /// escribir exactamente qué quiere que ARTattoo AI analice.
  Future<void> _pickImage() async {
    if (_busy) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachedBytes = bytes;
      _attachedMime = _mimeFor(image.path);
      _attachedName = image.name;
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final imageBytes = _attachedBytes;
    final imageMime = _attachedMime;
    final hasImage = imageBytes != null;

    // Una imagen puede enviarse sola; en ese caso se utiliza un análisis
    // profesional completo por defecto.
    if (text.isEmpty && !hasImage) return;
    if (_busy) return;

    if (hasImage) {
      final imageUsed = await ImageQuotaService.usedToday();
      if (imageUsed >= ImageQuotaService.dailyLimit) {
        _showError(
          'Has alcanzado el máximo de ${ImageQuotaService.dailyLimit} análisis de imágenes de hoy. El contador se reinicia mañana.',
        );
        return;
      }
    } else {
      final chatUsed = await ChatQuotaService.usedToday();
      if (chatUsed >= ChatQuotaService.dailyLimit) {
        _showError(
          'Has alcanzado el máximo de ${ChatQuotaService.dailyLimit} mensajes de chat de hoy. El contador se reinicia mañana.',
        );
        return;
      }
    }

    final userInstruction = text.isEmpty
        ? '''Haz un análisis profesional y muy detallado de esta imagen para tatuaje.
No quiero que generes otra imagen. Quiero que analices la imagen que te adjunto.
Explica qué estás viendo, qué funciona, qué problemas tiene y cómo la adaptarías a un tatuaje profesional.'''
        : '''Analiza la imagen adjunta siguiendo exactamente esta orden del usuario:

"$text"

No generes una imagen. Quiero un análisis visual y técnico de la imagen, con observaciones concretas, argumentos y recomendaciones aplicables al tatuaje.''';

    final visibleUserText = hasImage
        ? '📷 Imagen adjunta\n${text.isEmpty ? 'Análisis profesional completo solicitado.' : text}'
        : text;

    // Capturamos los datos antes de limpiar el compositor.
    _input.clear();
    setState(() {
      _attachedBytes = null;
      _attachedMime = null;
      _attachedName = null;
      _messages.add(_Message.user(visibleUserText));
      _busy = true;
    });
    _scrollDown();

    try {
      final key = await SettingsService.getGeminiApiKey();
      final model = await SettingsService.getGeminiModel();

      if (hasImage) {
        final answer = await _service.analyzeImage(
          apiKey: key,
          model: model,
          bytes: imageBytes,
          mimeType: imageMime ?? 'image/jpeg',
          instruction: userInstruction,
        );

        final usedAfter = await ImageQuotaService.consume();
        if (!mounted) return;
        setState(() {
          _imageUsed = usedAfter;
          _messages.add(_Message.ai(answer));
        });
      } else {
        final history = _messages
            .map(
              (message) => <String, String>{
                'role': message.role,
                'content': message.text,
              },
            )
            .toList();

        final answer = await _service.chat(
          apiKey: key,
          model: model,
          history: history,
        );

        final chatUsedAfter = await ChatQuotaService.consume();
        if (!mounted) return;
        setState(() {
          _chatUsed = chatUsedAfter;
          _messages.add(_Message.ai(answer));
        });
      }
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  String _mimeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  void _removeAttachment() {
    setState(() {
      _attachedBytes = null;
      _attachedMime = null;
      _attachedName = null;
    });
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text.replaceFirst('AiServiceException: ', '')),
      ),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ARTattoo AI',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'Gemini · análisis · tatuaje · dibujo · diseño',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Adjuntar imagen para analizar',
            onPressed: _busy ? null : _pickImage,
            icon: const Icon(Icons.image_search_rounded),
          ),
          IconButton(
            tooltip: 'Información',
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
        child: Column(
          children: <Widget>[
            _quotaBar(theme),
            Expanded(
              child: _messages.isEmpty ? _welcome(theme) : _chat(),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _quotaBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.chat_bubble_outline_rounded, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chat: $_chatUsed/${ChatQuotaService.dailyLimit} mensajes hoy',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              if (_chatUsed >= ChatQuotaService.dailyLimit) const Icon(Icons.lock_clock_rounded, size: 17),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Icon(Icons.image_search_rounded, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Imágenes: $_imageUsed/${ImageQuotaService.dailyLimit} análisis hoy',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              if (_imageUsed >= ImageQuotaService.dailyLimit) const Icon(Icons.lock_clock_rounded, size: 17),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcome(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: <Widget>[
        const SizedBox(height: 30),
        Icon(
          Icons.auto_awesome_rounded,
          size: 54,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 18),
        const Text(
          'Tu mentor creativo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          'Haz preguntas técnicas o adjunta una imagen y escribe exactamente qué quieres que analice. '
          'ARTattoo AI no crea imágenes aquí: las estudia y te da una crítica detallada para tatuaje, dibujo y diseño.',
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.45,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _promptChip('Critica la composición de un sleeve de brazo completo.'),
        _promptChip('Cómo puedo mejorar valores y contraste en blackwork?'),
        _promptChip('Qué líneas conservarías para convertir una referencia en stencil limpio?'),
      ],
    );
  }

  Widget _promptChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          _input.text = text;
          _send();
        },
      ),
    );
  }

  Widget _chat() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      itemCount: _messages.length + (_busy ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return const _Typing();

        final message = _messages[index];
        final isUser = message.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 390),
            decoration: BoxDecoration(
              color: isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              message.text,
              style: const TextStyle(height: 1.5),
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    final hasAttachment = _attachedBytes != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (hasAttachment) _attachmentPreview(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton.filledTonal(
                  tooltip: 'Adjuntar imagen para analizar',
                  onPressed: _busy ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: hasAttachment
                          ? 'Escribe qué quieres que analice de esta imagen...'
                          : 'Pregunta sobre tatuaje, dibujo o diseño...',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton.filled(
                  tooltip: hasAttachment ? 'Analizar imagen' : 'Enviar',
                  onPressed: _busy ? null : _send,
                  icon: Icon(hasAttachment ? Icons.analytics_rounded : Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentPreview() {
    final bytes = _attachedBytes;
    if (bytes == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              bytes,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Imagen lista para análisis',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  _attachedName ?? 'Imagen adjunta',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar imagen',
            onPressed: _busy ? null : _removeAttachment,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 10, 22, 30),
            child: Text(
              'ARTattoo AI usa Gemini para conversar y analizar imágenes. Las imágenes se pueden adjuntar desde la barra de escritura y acompañar de una orden específica, por ejemplo: «Analiza únicamente el flujo, el negativo y qué líneas conservarías para stencil». La respuesta está configurada para ser argumentada y detallada. No genera una imagen en este apartado: analiza la referencia y devuelve texto. El nivel gratuito de Google está sujeto a cuotas y límites que pueden cambiar. ARTattoo limita localmente el chat a 30 mensajes y el análisis a 100 imágenes por día. La API key se guarda localmente; para una distribución pública es más seguro usar un backend propio.',
              style: TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
        );
      },
    );
  }
}

class _Message {
  const _Message(this.role, this.text);

  factory _Message.user(String text) => _Message('user', text);
  factory _Message.ai(String text) => _Message('assistant', text);

  final String role;
  final String text;
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox(
          width: 38,
          child: Row(
            children: <Widget>[
              Expanded(child: _Dot()),
              Expanded(child: _Dot()),
              Expanded(child: _Dot()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: CircleAvatar(radius: 3),
    );
  }
}
