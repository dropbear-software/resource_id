import 'dart:math';
import 'dart:typed_data';

import 'package:base32_codec/base32_codec.dart';
import 'package:meta/meta.dart';

/// An immutable, type-safe resource identifier based on the principles
/// of robust API design.
///
/// This class handles:
/// - Resource type prefixes (e.g., "books/")
/// - Hierarchical paths (e.g., "books/1/pages/2")
/// - Secure random byte generation
/// - Crockford's Base32 encoding for readability
/// - Modulo-37 checksums to detect typos
@immutable
final class ResourceId {
  /// The collection name for this resource (e.g., "books").
  final String resourceType;

  /// The raw, unique bytes for this resource.
  final Uint8List bytes;

  /// The parent resource ID, if this resource is part of a hierarchy.
  final ResourceId? parent;

  /// The Crockford's Base32 codec used for all encoding/decoding.
  static final _codec = Base32Codec.crockford();

  /// The 37-character alphabet for encoding checksum values (0-36).
  static const _checksumAlphabet = r'0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U';

  /// Creates a new [ResourceId] instance.
  ///
  /// This constructor is private to ensure all instances are created
  /// through the validated [ResourceId.generate] or [ResourceId.parse] methods.
  const ResourceId._({
    required this.resourceType,
    required this.bytes,
    this.parent,
  });

  /// Generates a new, cryptographically secure [ResourceId].
  ///
  /// This is the recommended way to create new identifiers.
  ///
  /// [resourceType] is the collection name (e.g., "books").
  /// [parent] is an optional parent ID for hierarchical resources.
  /// [sizeInBytes] defaults to 8 (64 bits), which is suitable for storage
  /// in a database `BIGINT` column and is recommended for most resources.
  /// For globally unique IDs (like UUIDs), 15 or 16 bytes (120-128 bits)
  /// is recommended.
  factory ResourceId.generate({
    required String resourceType,
    ResourceId? parent,
    int sizeInBytes = 8,
  }) {
    if (sizeInBytes < 1) {
      throw ArgumentError.value(
        sizeInBytes,
        'sizeInBytes',
        'Must be at least 1',
      );
    }
    // Use a cryptographically secure random number generator.
    final random = Random.secure();
    final bytes = Uint8List(sizeInBytes);
    for (var i = 0; i < sizeInBytes; i++) {
      bytes[i] = random.nextInt(256);
    }

    return ResourceId._(
      resourceType: resourceType,
      bytes: bytes,
      parent: parent,
    );
  }

  /// Parses a full identifier string (e.g., "books/AHM6A83HENMP~")
  /// into a validated [ResourceId] instance.
  ///
  /// This method recursively parses hierarchical paths and validates
  /// the checksum of the final ID segment.
  ///
  /// Throws a [FormatException] if the string is invalid, has a
  /// checksum mismatch, or is improperly formatted.
  factory ResourceId.parse(String fullId) {
    if (fullId.isEmpty) {
      throw FormatException('Identifier cannot be empty.');
    }

    final parts = fullId.split('/');
    if (parts.length < 2 || parts.any((p) => p.isEmpty)) {
      throw FormatException(
        "Invalid ID format. Must be at least 'resourceType/id'.",
      );
    }

    // The last two parts are the resource type and the ID value
    final idWithChecksum = parts.last;
    final resourceType = parts[parts.length - 2];

    // Everything else forms the parent path, which we parse recursively
    ResourceId? parent;
    final parentParts = parts.sublist(0, parts.length - 2);
    if (parentParts.isNotEmpty) {
      parent = ResourceId.parse(parentParts.join('/'));
    }

    // Now, validate the final ID part
    if (idWithChecksum.length < 2) {
      throw FormatException('Invalid ID: Missing value or checksum.');
    }

    final encodedValue = idWithChecksum.substring(0, idWithChecksum.length - 1);
    final checksumChar = idWithChecksum[idWithChecksum.length - 1];

    // Decode using the "friendly" Crockford's codec.
    final Uint8List bytes;
    try {
      bytes = _codec.decode(encodedValue);
    } catch (e) {
      throw FormatException('Invalid Base32 format: $e');
    }

    // Verify the checksum
    final expectedChar = _getChecksumCharacter(_calculateChecksum(bytes));
    if (checksumChar != expectedChar) {
      // This is a key feature: distinguishing typos from "not found"
      throw FormatException(
        'Invalid identifier: Checksum mismatch. Possible typo.',
      );
    }

    return ResourceId._(
      resourceType: resourceType,
      bytes: bytes,
      parent: parent,
    );
  }

  /// Reconstructs a [ResourceId] from its raw bytes.
  ///
  /// This is useful when retrieving an ID from a database that stores it
  /// as a `BINARY` or `BLOB` type.
  factory ResourceId.fromBytes({
    required String resourceType,
    required Uint8List bytes,
    ResourceId? parent,
  }) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'Cannot be empty. Must contain at least 1 byte.',
      );
    }
    return ResourceId._(
      resourceType: resourceType,
      bytes: bytes,
      parent: parent,
    );
  }

  /// Reconstructs a [ResourceId] from a [BigInt].
  ///
  /// This is useful when retrieving an ID from a database that stores it
  /// as a `BIGINT` type, which is often more performant for indexing and
  /// joins than a `BINARY` type.
  ///
  /// ## Why is `sizeInBytes` required?
  ///
  /// When converting a byte array to an integer, information about leading
  /// zeros is lost. For example, `[0, 0, 1]` and `[1]` both become `BigInt(1)`.
  /// To ensure the original byte array can be perfectly reconstructed, you
  /// must provide the original fixed size of the identifier.
  ///
  /// It is best practice to use a fixed byte size for all identifiers of a
  /// specific [resourceType].
  ///
  /// Example:
  /// ```dart
  /// const USER_ID_SIZE = 8;
  ///
  /// // Store in DB
  /// final id = ResourceId.generate(resourceType: 'users', sizeInBytes: USER_ID_SIZE);
  /// final bigIntValue = id.asBigInt;
  ///
  /// // Retrieve from DB
  /// final reconstructedId = ResourceId.fromBigInt(
  ///   resourceType: 'users',
  ///   value: bigIntValue,
  ///   sizeInBytes: USER_ID_SIZE, // Provide the known, fixed size
  /// );
  /// ```
  factory ResourceId.fromBigInt({
    required String resourceType,
    required BigInt value,
    required int sizeInBytes,
    ResourceId? parent,
  }) {
    if (sizeInBytes < 1) {
      throw ArgumentError.value(
        sizeInBytes,
        'sizeInBytes',
        'Must be at least 1',
      );
    }
    final hex = value.toRadixString(16).padLeft(sizeInBytes * 2, '0');
    if (hex.length > sizeInBytes * 2) {
      throw ArgumentError(
        'BigInt value is too large for the specified sizeInBytes.',
      );
    }

    final bytes = _hexToBytes(hex);
    return ResourceId._(
      resourceType: resourceType,
      bytes: bytes,
      parent: parent,
    );
  }

  /// Reconstructs a [ResourceId] from its Base32-encoded [value].
  ///
  /// This is the counterpart to the [value] getter and is useful when
  /// retrieving an ID from a key-value store that stores the pure
  /// identifier value as a string.
  factory ResourceId.fromValue({
    required String resourceType,
    required String value,
    ResourceId? parent,
  }) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Can not be empty');
    }
    final bytes = _codec.decode(value);
    return ResourceId._(
      resourceType: resourceType,
      bytes: bytes,
      parent: parent,
    );
  }

  /// The size of the identifier in bytes.
  int get sizeInBytes => bytes.length;

  /// Returns the pure Base32-encoded value without the prefix or checksum.
  ///
  /// Useful for storing in a key-value database as a string.
  /// To reconstruct the ID, use the [ResourceId.fromValue] factory.
  String get value => _codec.encode(bytes);

  /// Returns the raw byte value as a [BigInt].
  ///
  /// Useful for storing in a database as a numeric type (e.g., `BIGINT`)
  /// for improved indexing and query performance.
  ///
  /// When converting back to a [ResourceId], you must use the
  /// [ResourceId.fromBigInt] constructor and provide the original `sizeInBytes`
  /// to ensure the ID is reconstructed correctly.
  BigInt get asBigInt {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return BigInt.parse(hex, radix: 16);
  }

  /// Serializes the [ResourceId] into its full string representation,
  /// including the resource path and checksum.
  @override
  String toString() {
    // 1. Get the Base32 value
    final encodedValue = _codec.encode(bytes);

    // 2. Calculate and append the checksum
    final checksumChar = _getChecksumCharacter(_calculateChecksum(bytes));
    final idPart = '$encodedValue$checksumChar';

    // 3. Get the parent's path recursively
    final parentPath = parent?.toString();

    // 4. Combine
    if (parentPath != null) {
      return '$parentPath/$resourceType/$idPart';
    } else {
      return '$resourceType/$idPart';
    }
  }

  /// Calculates the checksum value (0-36) from the raw bytes.
  static int _calculateChecksum(Uint8List bytes) {
    // 1. Convert the byte buffer into a BigInt value.
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // Handle empty bytes case
    final intValue = hex.isEmpty ? BigInt.zero : BigInt.parse(hex, radix: 16);

    // 2. Calculate the remainder after dividing by 37.
    final remainder = intValue % BigInt.from(37);
    return remainder.toInt();
  }

  /// Encodes the checksum value (0-36) into its special character.
  static String _getChecksumCharacter(int checksumValue) {
    return _checksumAlphabet[checksumValue.abs()];
  }

  /// Converts a hex string to a [Uint8List].
  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byteString = hex.substring(i, i + 2);
      final byte = int.parse(byteString, radix: 16);
      bytes.add(byte);
    }
    return Uint8List.fromList(bytes);
  }

  /// Returns the full string representation, suitable for JSON serialization.
  String toJson() => toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // We can safely compare the string representations, as they
    // uniquely and immutably represent the entire state (path + id).
    return other is ResourceId && other.toString() == toString();
  }

  @override
  int get hashCode => toString().hashCode;
}
