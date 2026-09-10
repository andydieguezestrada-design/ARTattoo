import 'package:flutter_test/flutter_test.dart';
import 'package:artattoo_academy/data/academy_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled tattoo content diagnostics', () async {
    final repository = AcademyRepository();
    final styles = await repository.loadStyles();
    final articles = await repository.loadArticles();

    expect(styles, isNotEmpty);
    expect(articles, isNotEmpty);
    expect(styles.first.name.trim(), isNotEmpty);
    expect(articles.first.title.trim(), isNotEmpty);
  });
}
