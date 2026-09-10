import 'package:flutter/material.dart';

import '../models/academy_models.dart';

class StyleDetailScreen extends StatelessWidget {
  const StyleDetailScreen({required this.style, super.key});

  final StyleProfile style;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(style.name)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
        Container(height: 190, decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFF2B2D35), Color(0xFF101116)])), child: const Center(child: Icon(Icons.brush_rounded, size: 84, color: Color(0xFFE7B85C)))),
        const SizedBox(height: 18),
        Text(style.description, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 22),
        _info(context, 'Historia', style.history),
        _info(context, 'Características técnicas', style.lines),
        _info(context, 'Técnicas y sombreado', style.shading),
        _info(context, 'Composición', style.composition),
        _info(context, 'Dificultad', style.difficulty),
        Text('Elementos frecuentes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: style.elements.map((e) => Chip(label: Text(e))).toList()),
        const SizedBox(height: 20),
        Text('Consejos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...style.tips.map((t) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline_rounded), title: Text(t))),
      ]),
    );
  }

  Widget _info(BuildContext context, String title, String value) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(value)]));
}
