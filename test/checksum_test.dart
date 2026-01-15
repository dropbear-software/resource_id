import 'package:resource_id/src/checksum.dart';
import 'package:test/test.dart';

void main() {
  group('Checksum', () {
    test('calculateChecksum returns correct modulo 37', () {
      // 37 in hex is 0x25.
      // If we have bytes that equal 37 (integer), checksum should be 0.
      expect(calculateChecksum([37]), 0);

      // 38 % 37 = 1
      expect(calculateChecksum([38]), 1);

      // Test larger number
      // [1, 0] = 256. 256 % 37 = 34.
      expect(calculateChecksum([1, 0]), 34);
    });

    test('getChecksumCharacter returns correct chars', () {
      expect(getChecksumCharacter(0), '0');
      expect(getChecksumCharacter(10), 'A');
      expect(getChecksumCharacter(32), '*');
      expect(getChecksumCharacter(36), 'U');
    });

    test('getChecksumCharacter throws on invalid input', () {
      expect(() => getChecksumCharacter(-1), throwsRangeError);
      expect(() => getChecksumCharacter(37), throwsRangeError);
    });

    test('getChecksumValue returns correct index', () {
      expect(getChecksumValue('0'), 0);
      expect(getChecksumValue('A'), 10);
      expect(getChecksumValue('*'), 32);
      expect(getChecksumValue('U'), 36);
      expect(getChecksumValue('u'), 36); // Case insensitive check
    });
  });
}
