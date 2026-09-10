import 'package:flutter/material.dart';

import '../models/academy_models.dart';
import '../widgets/style_card.dart';

class StylesScreen extends StatelessWidget {
  const StylesScreen({required this.styles, required this.onTap, super.key});

  final List<StyleProfile> styles;
  final void Function(StyleProfile) onTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Style Explorer', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Explora historia, técnica, composición y dificultad de cada estilo.')]))) ,
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 30), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, index) => StyleCard(style: styles[index], onTap: () => onTap(styles[index])), childCount: styles.length), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 280, mainAxisExtent: 250, crossAxisSpacing: 12, mainAxisSpacing: 12))),
    ]);
  }
}
