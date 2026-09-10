import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';
import '../services/image_quota_service.dart';
import '../services/chat_quota_service.dart';
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

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;

    final chatUsed = await ChatQuotaService.usedToday();
    if (chatUsed >= ChatQuotaService.dailyLimit) {
      _showError(
        'Has alcanzado el máximo de ${ChatQuotaService.dailyLimit} mensajes de chat de hoy. El contador se reinicia mañana.',
      );
      return;
    }

    _input.clear();
    setState(() {
      _messages.add(_Message.user(text));
      _busy = true;
    });
    _scrollDown();

    try {
      final key = await SettingsService.getGeminiApiKey();
      final model = await SettingsService.getGeminiModel();
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
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  Future<void> _pickAndAnalyze() async {
    if (_busy) return;

    final used = await ImageQuotaService.usedToday();
    if (used >= ImageQuotaService.dailyLimit) {
      _showError(
        'Has alcanzado el máximo de ${ImageQuotaService.dailyLimit} análisis de imágenes de hoy. El contador se reinicia mañana.',
      );
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (image == null) return;

    final Uint8List bytes = await image.readAsBytes();
    final String mime = _mimeFor(image.path);

    setState(() {
      _messages.add(_Message.user('📷 Analiza esta referencia para tatuaje.'));
      _busy = true;
    });
    _scrollDown();

    try {
      final key = await SettingsService.getGeminiApiKey();
      final model = await SettingsService.getGeminiModel();
      final answer = await _service.analyzeImage(
        apiKey: key,
        model: model,
        bytes: bytes,
        mimeType: mime,
        instruction:
            'Analiza esta imagen como referencia para un tatuador. Describe de forma práctica: '
            '1) composición y flujo, 2) anatomía y proporciones si aplica, '
            '3) masas de negro y zonas de negativo, 4) líneas y detalles internos que conviene conservar, '
            '5) contraste y valores, 6) posibles problemas al convertirla en stencil de líneas limpias, '
            '7) recomendaciones concretas para rediseñarla para tatuaje. '
            'No inventes detalles que no sean visibles.',
      );

      final usedAfter = await ImageQuotaService.consume();
      if (!mounted) return;
      setState(() {
        _imageUsed = usedAfter;
        _messages.add(_Message.ai(answer));
      });
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
    return 'image/jpeg';
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
              'Gemini · tatuaje · dibujo · diseño',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Analizar imagen',
            onPressed: _busy ? null : _pickAndAnalyze,
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
              Expanded(child: Text('Chat: $_chatUsed/${ChatQuotaService.dailyLimit} mensajes hoy', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              if (_chatUsed >= ChatQuotaService.dailyLimit) const Icon(Icons.lock_clock_rounded, size: 17),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Icon(Icons.image_search_rounded, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Imágenes: $_imageUsed/${ImageQuotaService.dailyLimit} análisis hoy', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
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
          'Consulta técnica, crítica de diseños y análisis de referencias. '
          'ARTattoo AI se mantiene enfocada en tatuaje, dibujo y diseño.',
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.45,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _promptChip('Critica la composición de un sleeve de brazo completo.'),
        _promptChip('Cómo puedo mejorar valores y contraste en blackwork?'),
        _promptChip(
          'Qué debo conservar al convertir una referencia en stencil de líneas?',
        ),
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
            constraints: const BoxConstraints(maxWidth: 370),
            decoration: BoxDecoration(
              color: isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              message.text,
              style: const TextStyle(height: 1.4),
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Analizar imagen',
              onPressed: _busy ? null : _pickAndAnalyze,
              icon: const Icon(Icons.add_photo_alternate_rounded),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Pregunta sobre tatuaje, dibujo o diseño...',
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
              tooltip: 'Enviar',
              onPressed: _busy ? null : _send,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
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
              'ARTattoo AI usa la API de Gemini. El modelo recomendado es Gemini 2.5 Flash. '
              'El nivel gratuito de Google está sujeto a cuotas y límites que pueden cambiar. '
              'ARTattoo limita localmente el chat a 30 mensajes y el análisis a 100 imágenes por día para controlar el consumo. '
              'La API key se guarda localmente en este dispositivo; para una distribución pública es más seguro usar un backend propio.',
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
