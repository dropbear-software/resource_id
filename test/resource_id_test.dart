import 'package:resource_id/resource_id.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceId', () {
    test('generate creates valid IDs', () {
      final id = ResourceId.generate();
      expect(id.bytes, hasLength(15)); // Default length
      expect(id.checksumChar, isNotNull);
      expect(id.toString(), matches(RegExp(r'^[0-9A-Z]+[*~$=U0-9A-Z]$')));
    });

    test('generate accepts custom length', () {
      final id = ResourceId.generate(byteLength: 5);
      expect(id.bytes, hasLength(5));
    });

    test('generate accepts type prefix', () {
      final id = ResourceId.generate(type: 'users');
      expect(id.type, 'users');
      expect(id.toString(), startsWith('users/'));
    });

    test('parse handles valid strings', () {
      final generated = ResourceId.generate();
      final stringRep = generated.toString();

      final parsed = ResourceId.parse(stringRep);
      expect(parsed, equals(generated));
      expect(parsed.type, generated.type);
    });

    test('parse handles hyphens and lowercase', () {
      final id = ResourceId.generate();
      final baseString = id.toString();
      final checksum = baseString.substring(baseString.length - 1);
      final payload = baseString.substring(0, baseString.length - 1);

      // Insert hyphen
      if (payload.length > 2) {
        final mangled =
            '${payload.substring(0, 2)}-${payload.substring(2)}$checksum';
        final parsed = ResourceId.parse(mangled.toLowerCase());
        expect(parsed.bytes, orderedEquals(id.bytes));
      }
    });

    test('parse handles type prefixes', () {
      final id = ResourceId.generate(type: 'books');
      final parsed = ResourceId.parse(id.toString());
      expect(parsed.type, 'books');
      expect(parsed.bytes, id.bytes);
    });

    test('parse handles complex paths as type', () {
      final id = ResourceId.generate();
      final idStr = id.toString();
      final path = 'books/123/pages/$idStr';

      final parsed = ResourceId.parse(path);
      expect(parsed.type, 'books/123/pages');
      expect(parsed.bytes, id.bytes);
    });

    test('parse handles hierarchical path with multiple IDs', () {
      // Scenario: books/BOOK_ID/pages/PAGE_ID
      final bookId = ResourceId.generate();
      final pageId = ResourceId.generate();

      final path = 'books/$bookId/pages/$pageId';
      final parsed = ResourceId.parse(path);

      expect(parsed.type, 'books/$bookId/pages');
      expect(parsed.bytes, pageId.bytes);
      expect(parsed.checksumChar, pageId.checksumChar);
    });
    test('parse throws on invalid checksum', () {
      final id = ResourceId.generate();
      var str = id.toString();
      // Replace last char with something else
      final lastChar = str[str.length - 1];
      final invalidLastChar = (lastChar == '0') ? '1' : '0';
      str = str.substring(0, str.length - 1) + invalidLastChar;

      expect(() => ResourceId.parse(str), throwsFormatException);
    });

    test('parse throws on invalid characters in payload', () {
      // 'U' is excluded from the Crockford Base32 payload alphabet.
      expect(() => ResourceId.parse('UUUUU0'), throwsFormatException);
    });

    test('isValid returns true for valid IDs', () {
      final id = ResourceId.generate();
      expect(ResourceId.isValid(id.toString()), isTrue);
    });

    test('isValid returns false for invalid IDs', () {
      expect(ResourceId.isValid('invalid'), isFalse);
    });

    test('bytes getter returns unmodifiable list', () {
      final id = ResourceId.generate();
      final bytes = id.bytes;
      expect(() => bytes[0] = 0, throwsUnsupportedError);
    });
  });
}
