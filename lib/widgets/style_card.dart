import 'package:flutter/material.dart';

import '../models/academy_models.dart';

class StyleCard extends StatelessWidget {
  const StyleCard({required this.style, required this.onTap, super.key});

  final StyleProfile style;
  final VoidCallback onTap;

  IconData _icon(String id) {
    switch (id) {
      case 'realism':
      case 'microrealism':
        return Icons.face_retouching_natural;
      case 'lettering':
        return Icons.text_fields_rounded;
      case 'geometric':
        return Icons.grid_4x4_rounded;
      case 'ornamental':
        return Icons.auto_awesome;
      case 'japanese':
        return Icons.water;
      default:
        return Icons.brush_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B1D24), Color(0xFF101116)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                  gradient: const LinearGradient(colors: [Color(0xFF252831), Color(0xFF111217)]),
                ),
                child: Center(child: Icon(_icon(style.id), size: 48, color: const Color(0xFFE7B85C))),
              ),
              const SizedBox(height: 12),
              Text(style.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 5),
              Text(style.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 9),
              Text(style.difficulty, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
