import 'dart:typed_data';

import 'package:resource_id/resource_id.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceId', () {
    const validIdFullString = 'books/BKB3XYT465KZ69';

    test('Throws ArgumentError if sizeInBytes is 0 when generating', () {
      expect(
        () => ResourceId.generate(resourceType: 'books', sizeInBytes: 0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Must be at least 1'),
          ),
        ),
      );
    });

    test('Can be generated', () {
      final id = ResourceId.generate(resourceType: 'books');
      expect(id, isA<ResourceId>());
      expect(id.resourceType, 'books');
      expect(id.parent, isNull);
    });

    test('Can parse a valid ID string', () {
      // Use a known-good generated ID to ensure checksum is valid
      final generatedId = ResourceId.generate(resourceType: 'books');
      final idString = generatedId.toString();

      final id = ResourceId.parse(idString);

      expect(id.resourceType, 'books');
      expect(id.parent, isNull);
      expect(id.bytes, equals(generatedId.bytes));
      expect(id.toString(), equals(idString));
    });

    test('Throws FormatException for invalid checksum (detects typos)', () {
      // This ID is valid, we will tamper with it
      final id = ResourceId.parse(validIdFullString);
      expect(id.toString(), validIdFullString);

      // Create a typo by changing a character in the value
      const badId = 'books/BKB3XYT465KZ68'; // 9 -> 8

      expect(
        () => ResourceId.parse(badId),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Checksum mismatch'),
          ),
        ),
      );
    });

    group('Friendly parser', () {
      test('handles mixed case', () {
        const messyId = 'books/bkb3xyt465kz69';
        final id = ResourceId.parse(messyId);
        expect(id.toString(), validIdFullString);
      });

      test('handles hyphens', () {
        const messyId = 'books/BKB3-XYT4-65KZ-69';
        final id = ResourceId.parse(messyId);
        expect(id.toString(), validIdFullString);
      });

      test('handles hyphens and mixed case', () {
        const messyId = 'books/bkb3-xyt4-65kz-69';
        final id = ResourceId.parse(messyId);
        expect(id.toString(), validIdFullString);
      });
    });

    test('Can create and parse hierarchical IDs', () {
      final parentId = ResourceId.parse(validIdFullString);

      // This part is random, so we can't test the exact string value
      final childId = ResourceId.generate(
        resourceType: 'pages',
        parent: parentId,
      );

      final childIdString = childId.toString();
      final parsedChild = ResourceId.parse(childIdString);

      expect(childIdString, startsWith('$validIdFullString/pages/'));
      expect(parsedChild.resourceType, 'pages');
      expect(parsedChild.parent, isNotNull);
      expect(parsedChild.parent, equals(parentId));
      expect(parsedChild.parent?.resourceType, 'books');
      expect(parsedChild.toString(), childIdString);
    });

    group('Equality', () {
      test('is case-insensitive', () {
        final id1 = ResourceId.parse(validIdFullString);
        final id2 = ResourceId.parse('books/bkb3xyt465kz69');
        final id3 = ResourceId.parse(
          'users/BKB3XYT465KZ69',
        ); // Same bytes, different type

        expect(id1, equals(id2));
        expect(id1.hashCode, equals(id2.hashCode));
        expect(id1, isNot(equals(id3)));
      });

      test('ignores hyphens', () {
        final id1 = ResourceId.parse(validIdFullString);
        final id2 = ResourceId.parse('books/BKB3-XYT4-65KZ-69');

        expect(id1, equals(id2));
        expect(id1.hashCode, equals(id2.hashCode));
      });

      test('ignores both case and hyphens', () {
        final id1 = ResourceId.parse(validIdFullString);
        final id2 = ResourceId.parse('books/bkb3-xyt4-65kz-69');

        expect(id1, equals(id2));
        expect(id1.hashCode, equals(id2.hashCode));
      });
    });

    group('Database serialization', () {
      test('Can be reconstructed from bytes', () {
        final originalId = ResourceId.generate(resourceType: 'users');

        // Simulate storing and retrieving
        final bytes = originalId.bytes;
        final reconstructedId = ResourceId.fromBytes(
          resourceType: 'users',
          bytes: bytes,
        );

        expect(reconstructedId, equals(originalId));
      });

      test('Can be reconstructed from BigInt', () {
        final originalId = ResourceId.generate(
          resourceType: 'products',
          sizeInBytes: 12, // Use a non-default size
        );

        // Simulate storing and retrieving
        final bigIntValue = originalId.asBigInt;
        final size = originalId.sizeInBytes;

        final reconstructedId = ResourceId.fromBigInt(
          resourceType: 'products',
          value: bigIntValue,
          sizeInBytes: size,
        );

        expect(reconstructedId, equals(originalId));
      });

      test(
        'Throws ArgumentError if sizeInBytes is 0 when reconstructing from BigInt',
        () {
          expect(
            () => ResourceId.fromBigInt(
              resourceType: 'products',
              value: BigInt.from(123),
              sizeInBytes: 0,
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('Must be at least 1'),
              ),
            ),
          );
        },
      );

      test(
        'Throws ArgumentError if value is empty when reconstructing from value',
        () {
          expect(
            () => ResourceId.fromValue(resourceType: 'products', value: ''),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('Can not be empty'),
              ),
            ),
          );
        },
      );

      test(
        'Throws ArgumentError if bytes is less than 1 byte when reconstructing fromBytes',
        () {
          expect(
            () => ResourceId.fromBytes(
              resourceType: 'products',
              bytes: Uint8List(0),
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('Must contain at least 1 byte'),
              ),
            ),
          );
        },
      );

      test('Can be reconstructed from value string', () {
        final originalId = ResourceId.generate(resourceType: 'invoices');

        // Simulate storing and retrieving for a key-value store
        final valueString = originalId.value;
        final reconstructedId = ResourceId.fromValue(
          resourceType: 'invoices',
          value: valueString,
        );

        expect(reconstructedId, equals(originalId));
      });

      test('Reconstruction with parent works correctly', () {
        final parentId = ResourceId.generate(resourceType: 'customers');
        final childId = ResourceId.generate(
          resourceType: 'orders',
          parent: parentId,
        );

        // From bytes
        final reconstructedFromBytes = ResourceId.fromBytes(
          resourceType: 'orders',
          bytes: childId.bytes,
          parent: parentId,
        );
        expect(reconstructedFromBytes, equals(childId));

        // From BigInt
        final reconstructedFromBigInt = ResourceId.fromBigInt(
          resourceType: 'orders',
          value: childId.asBigInt,
          sizeInBytes: childId.sizeInBytes,
          parent: parentId,
        );
        expect(reconstructedFromBigInt, equals(childId));

        // From value
        final reconstructedFromValue = ResourceId.fromValue(
          resourceType: 'orders',
          value: childId.value,
          parent: parentId,
        );
        expect(reconstructedFromValue, equals(childId));
      });
    });

    test('toString returns the full canonical path', () {
      final id = ResourceId.parse(validIdFullString);
      expect(id.toString(), validIdFullString);
    });
  });
}
