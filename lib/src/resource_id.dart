import 'dart:math';
import 'dart:typed_data';
import 'package:base32_codec/base32_codec.dart';
import 'package:meta/meta.dart';
import 'checksum.dart';

/// Represents a Resource Identifier based on Crockford's Base32 encoding
/// with a modulo-37 checksum.
@immutable
class ResourceId {
  /// The optional type prefix (e.g., "books").
  final String? type;

  /// The raw random bytes that make up the unique portion of the identifier.
  final List<int> _bytes;

  /// The checksum character derived from [bytes].
  final String checksumChar;

  static final _codec = Base32Codec.crockford();

  ResourceId._(this.type, List<int> bytes, this.checksumChar)
    : _bytes = List.unmodifiable(bytes);

  /// Returns a copy of the raw bytes.
  List<int> get bytes => _bytes;

  /// Returns the raw bytes for storage.
  List<int> toBytes() => _bytes;

  /// Generates a new random [ResourceId].
  ///
  /// The [type] is an optional resource type prefix.
  /// The [byteLength] determines the size of the random payload (defaults to 15, approx 120 bits of entropy).
  factory ResourceId.generate({String? type, int byteLength = 15}) {
    final random = Random.secure();
    final bytes = Uint8List(byteLength);
    for (var i = 0; i < byteLength; i++) {
      bytes[i] = random.nextInt(256);
    }

    final checksumVal = calculateChecksum(bytes);
    final checksumChar = getChecksumCharacter(checksumVal);

    return ResourceId._(type, bytes, checksumChar);
  }

  /// Parses a string representation of a [ResourceId].
  ///
  /// Accepts formats like:
  /// - `AHM6A83HENMP~`
  /// - `books/AHM6A83HENMP~`
  /// - `books/ahm6-a83h-enmp~` (hyphens and lowercase allowed)
  ///
  /// Throws a [FormatException] if the [input] is invalid (e.g., bad checksum, invalid characters).
  factory ResourceId.parse(String input) {
    if (input.isEmpty) {
      throw FormatException('ResourceId cannot be empty');
    }

    String? type;
    var idPart = input;

    // 1. Separate Type
    if (input.contains('/')) {
      // Treats the last segment as the ID and the preceding path as the type.
      final lastSlashIndex = input.lastIndexOf('/');
      type = input.substring(0, lastSlashIndex);
      idPart = input.substring(lastSlashIndex + 1);
    }

    if (idPart.length < 2) {
      throw FormatException('ID part too short');
    }

    // 2. Extract Checksum (last char)
    final checksumChar = idPart.substring(idPart.length - 1);
    final payloadStr = idPart.substring(0, idPart.length - 1);

    // 3. Decode Payload
    // The decoder handles case insensitivity and ignores hyphens.
    List<int> decodedBytes;
    try {
      decodedBytes = _codec.decode(payloadStr);
    } catch (e) {
      throw FormatException('Invalid Base32 encoding: $e');
    }

    // 4. Verify Checksum
    final calculatedChecksum = calculateChecksum(decodedBytes);
    final expectedChar = getChecksumCharacter(calculatedChecksum);

    // Normalize checksum char for comparison.
    if (checksumChar.toUpperCase() != expectedChar) {
      throw FormatException(
        'Invalid checksum. Expected $expectedChar, got $checksumChar',
      );
    }

    return ResourceId._(type, decodedBytes, expectedChar);
  }

  /// Checks if the [input] is a valid ResourceId string.
  static bool isValid(String input) {
    try {
      ResourceId.parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  String toString() {
    // Encode bytes to Crockford Base32
    final encoded = _codec.encode(Uint8List.fromList(_bytes));

    // Checksum is already stored, but ensure it matches casing if we want consistency.
    // Base32Codec output is usually uppercase.
    final suffix = checksumChar;

    if (type != null) {
      return '$type/$encoded$suffix';
    }
    return '$encoded$suffix';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResourceId &&
        other.type == type &&
        _listEquals(other._bytes, _bytes) &&
        other.checksumChar == checksumChar;
  }

  @override
  int get hashCode => Object.hash(type, Object.hashAll(_bytes), checksumChar);

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
