import 'package:resource_id/resource_id.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final bookId = ResourceId.generate(resourceType: 'books');

    test('First Test', () {
      expect(bookId.resourceType, equals('books'));
    });
  });
}
