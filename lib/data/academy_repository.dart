import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/academy_models.dart';

class AcademyRepository {
  Future<List<StyleProfile>> loadStyles() async {
    final raw = await rootBundle.loadString('assets/data/styles.json');
    final list = jsonDecode(raw) as List<dynamic>;

    return list.map((item) {
      final map = item as Map<String, dynamic>;

      return StyleProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        history: map['history'] as String,
        lines: map['lines'] as String,
        shading: map['shading'] as String,
        composition: map['composition'] as String,
        difficulty: map['difficulty'] as String,
        elements: List<String>.from(map['elements'] as List<dynamic>),
        tips: List<String>.from(map['tips'] as List<dynamic>),
      );
    }).toList();
  }

  // ===========================================================================
  // ENCICLOPEDIA PROFESIONAL
  // ===========================================================================

  Future<List<AcademyArticle>> loadArticles() async {
    final raw = await rootBundle.loadString(
      'assets/data/articles.json',
    );

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException(
        'assets/data/articles.json debe contener una lista de artículos.',
      );
    }

    return decoded.map<AcademyArticle>((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Cada artículo debe ser un objeto JSON válido.',
        );
      }

      final sections = item['sections'];

      if (sections is! List) {
        throw const FormatException(
          'Cada artículo debe contener una lista "sections".',
        );
      }

      return AcademyArticle(
        id: item['id'] as String,
        category: item['category'] as String,
        title: item['title'] as String,
        summary: item['summary'] as String,
        sections: sections.map<AcademyArticleSection>((section) {
          if (section is! Map<String, dynamic>) {
            throw const FormatException(
              'Cada sección debe ser un objeto JSON válido.',
            );
          }

          final body = section['body'];

          if (body is! List) {
            throw const FormatException(
              'Cada sección debe contener una lista "body".',
            );
          }

          return AcademyArticleSection(
            title: section['title'] as String,
            body: List<String>.from(body),
            image: section['image'] as String?,
          );
        }).toList(),
      );
    }).toList();
  }

  Future<List<AcademyArticle>> loadArticlesByCategory(
    String category,
  ) async {
    final articles = await loadArticles();

    return articles
        .where(
          (article) =>
              article.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  Future<AcademyArticle?> findArticleById(String id) async {
    final articles = await loadArticles();

    for (final article in articles) {
      if (article.id == id) {
        return article;
      }
    }

    return null;
  }

  Future<List<String>> loadArticleCategories() async {
    final articles = await loadArticles();

    final categories = <String>{};

    for (final article in articles) {
      final category = article.category.trim();

      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    final result = categories.toList();
    result.sort();

    return result;
  }
}