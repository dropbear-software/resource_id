# Resource ID

A Dart package for generating, parsing, and verifying resource identifiers using
[Crockford's Base32](https://www.crockford.com/base32.html) encoding with a
modulo-37 checksum.

This package implements the specification for robust, user-friendly, and secure
resource identifiers.

## Features

- **Secure Random Generation**: Uses `Random.secure()` (cryptographically secure
  random bytes).
- **Crockford Base32**: Human-readable, URL-safe, case-insensitive, and ignores
  hyphens.
- **Checksum Verification**: Built-in modulo-37 checksum detects typos and
  invalid IDs immediately.
- **Raw Byte Access**: Exposes the underlying random bytes for efficient
  database storage (e.g., as `BINARY` or large integers).
- **Hierarchical Support**: Supports parsing identifiers with path contexts
  (e.g., `books/123/pages/456` resolves to the leaf ID `456` with context
  `books/123/pages`).

## Usage

### 1. Generating Identifiers

```dart
import 'package:resource_id/resource_id.dart';

void main() {
  // Generate a random ID (default 15 bytes of entropy)
  final id = ResourceId.generate();
  print(id); // e.g. "0123456789ABCDE~"

  // Generate with a type prefix
  final bookId = ResourceId.generate(type: 'books');
  print(bookId); // e.g. "books/0123456789ABCDE~"
  
  // Access raw bytes for storage
  List<int> bytes = bookId.bytes;
}
```

### 2. Parsing and Verifying

```dart
try {
  // Parse a string (handles hyphens and casing)
  final id = ResourceId.parse('books/0123-4567-89ab-cde~');
  
  print('Type: ${id.type}'); // "books"
  print('Valid checksum: ${id.checksumChar}');
  
} catch (e) {
  print('Invalid ID: $e');
}

// Check validity without throwing
if (ResourceId.isValid('invalid-id')) {
  // ...
}
```

### 3. Hierarchical Identifiers

The package supports hierarchical paths. When parsing a path, the last segment is
treated as the unique ID, and the preceding path is preserved as the `type`.

```dart
final path = 'books/AHM6/pages/B7K9~';
final id = ResourceId.parse(path);

print(id.type); // "books/AHM6/pages"
print(id.toString()); // "books/AHM6/pages/B7K9~" (normalized)
```

## Format Specification

*   **Encoding**: Crockford Base32.
*   **Checksum**: Modulo-37 (`value % 37`).
*   **Alphabet**: `0123456789ABCDEFGHJKMNPQRSTVWXYZ` (32 chars) + `*~$=U` (5
    checksum-only chars).
*   **Structure**: `[optional_type_prefix/][base32_payload][checksum_char]`