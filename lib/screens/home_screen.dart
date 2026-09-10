import 'package:flutter/material.dart';

import '../data/academy_repository.dart';
import '../models/academy_models.dart';
import '../theme/app_theme.dart';
import 'ai_tattoo_screen.dart';
import 'encyclopedia_screen.dart';
import 'settings_support_screen.dart';
import 'style_detail_screen.dart';
import 'styles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.repository, super.key});

  final AcademyRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  List<StyleProfile> _styles = const [];
  bool _loading = true;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    try {
      final styles = await widget.repository.loadStyles();
      if (!mounted) return;
      setState(() {
        _styles = styles;
        _loading = false;
      });
    } catch (error) {
      debugPrint('ARTattoo: content load error: $error');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildDashboard(),
      EncyclopediaScreen(repository: widget.repository),
      StylesScreen(
        styles: _styles,
        onTap: (style) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StyleDetailScreen(style: style)),
        ),
      ),
      const AiTattooScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Enciclopedia',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'Estilos',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'IA Tattoo',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _glow,
                builder: (context, child) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(AppTheme.accent, Colors.white, _glow.value * .18)!,
                        AppTheme.accent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: .16 + .12 * _glow.value),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Icon(Icons.brush_rounded, color: Colors.black),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ARTATTOO\nSTUDIO',
                  style: TextStyle(fontSize: 20, height: .9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
              IconButton(
                tooltip: 'Ajustes y soporte',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsSupportScreen()),
                ),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'Tu espacio para\ntatuaje, dibujo y diseño.',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sin ejercicios ni clases. Una biblioteca técnica y un mentor de IA para ayudarte a crear mejor.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 24),
          _AnimatedFeatureCard(
            delay: 0,
            icon: Icons.auto_awesome_rounded,
            title: 'ARTattoo AI',
            subtitle: 'Mentor online especializado en tatuaje, dibujo y diseño.',
            accent: AppTheme.accent,
            onTap: () => setState(() => _index = 3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AnimatedFeatureCard(
                  delay: 100,
                  icon: Icons.menu_book_rounded,
                  title: 'Enciclopedia',
                  subtitle: 'Técnica y referencia.',
                  onTap: () => setState(() => _index = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedFeatureCard(
                  delay: 180,
                  icon: Icons.style_rounded,
                  title: 'Estilos',
                  subtitle: '${_styles.length} perfiles.',
                  onTap: () => setState(() => _index = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Consejo de estudio: usa la IA para cuestionar decisiones de composición, valores y flujo; no para sustituir tu propio criterio.',
                      style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFeatureCard extends StatefulWidget {
  const _AnimatedFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
    this.delay = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;
  final int delay;

  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? Theme.of(context).colorScheme.primary;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: .13), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(widget.icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(widget.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.3)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
