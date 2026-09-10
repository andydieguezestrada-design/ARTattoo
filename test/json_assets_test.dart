import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets/data contiene JSON valido', () {
    final dir = Directory('assets/data');
    expect(dir.existsSync(), true);
    for (final file in dir.listSync().whereType<File>()) {
      if (file.path.endsWith('.json')) {
        jsonDecode(file.readAsStringSync());
      }
    }
  });
}
