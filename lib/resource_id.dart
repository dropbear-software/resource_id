/// A Dart package for creating, parsing, and validating robust, immutable,
/// and URL-safe resource identifiers.
///
/// This package provides an immutable `ResourceId` class that enforces modern
/// API design principles. It generates prefixed identifiers (e.g.,
/// `books/9V233V10702ETQW3S1WKTZ~`) that are easy to read, copy, and debug,
/// with built-in checksums to detect typos.
///
/// The implementation is based on the strong recommendations for great resource
/// identifiers in the book API Design Patterns by J.J Geewax.
///
/// ## Usage
///
/// A simple usage example:
///
/// ```dart
/// import 'package:resource_id/resource_id.dart';
///
/// void main() {
///   // Generate a new ID for a "books" collection
///   final newBookId = ResourceId.generate(resourceType: 'books');
///
///   // The toString() method includes the type prefix and checksum
///   print(newBookId);
///   // Output: books/9V233V10702ETQW3S1WKTZ~ (random part will vary)
///
///   // Parse and validate an ID from a string.
///   // A FormatException is thrown if the checksum is invalid (e.g., a typo).
///   try {
///     // Note the typo: 'Z' was mistyped as 'X'
///     final badId = 'books/9V233V10702ETQW3S1WKTX~';
///     ResourceId.parse(badId);
///   } on FormatException catch (e) {
///     print(e.message);
///     // Output: Invalid identifier: Checksum mismatch. Possible typo.
///   }
/// }
/// ```
library;

export 'src/resource_id_base.dart';
