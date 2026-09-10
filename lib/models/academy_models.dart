class StyleProfile {
  const StyleProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.history,
    required this.lines,
    required this.shading,
    required this.composition,
    required this.difficulty,
    required this.elements,
    required this.tips,
  });

  final String id;
  final String name;
  final String description;
  final String history;
  final String lines;
  final String shading;
  final String composition;
  final String difficulty;
  final List<String> elements;
  final List<String> tips;
}

class AcademyArticle {
  const AcademyArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.sections,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final List<AcademyArticleSection> sections;
}

class AcademyArticleSection {
  const AcademyArticleSection({
    required this.title,
    required this.body,
    this.image,
  });

  final String title;
  final List<String> body;
  final String? image;
}
