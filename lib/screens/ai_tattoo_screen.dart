import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AiTattooScreen extends StatefulWidget {
  const AiTattooScreen({super.key});

  @override
  State<AiTattooScreen> createState() => _AiTattooScreenState();
}

class _AiTattooScreenState extends State<AiTattooScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  late final AnimationController _intro;
  int _progress = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) => setState(() => _progress = value),
          onPageFinished: (_) => setState(() => _loaded = true),
        ),
      )
      ..loadFlutterAsset('assets/ai/tattoo_ai.html');
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ARTattoo AI', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Información de la IA',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22, 10, 22, 30),
                  child: Text(
                    'ARTattoo AI es un mentor online especializado en tatuaje, dibujo y diseño. Usa Puter para acceder a modelos de IA sin que ARTattoo tenga que guardar una API key dentro del APK. El acceso gratuito depende de la cuenta y las condiciones vigentes del servicio.',
                    style: TextStyle(fontSize: 15, height: 1.45),
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
        child: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (!_loaded)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
