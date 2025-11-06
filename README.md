A Dart package for creating, parsing, and validating robust, immutable, and K-Sortable resource identifiers.

This package provides an immutable `ResourceId` class that enforces modern API design principles. It generates prefixed, URL-safe identifiers (e.g., `books/64s36d1n6rvkge9gc5h66~`) that are easy to read, copy, and debug, with built-in checksums to detect typos.

This implementation is based on the strong recommendations for great resource identifiers in the book API Design Patterns by J.J Geewax.

## Features

This package provides a `ResourceId` class with the following features:

* **Immutable & Type-Safe:** Enforces correctness at compile time.
* **Prefix-Aware:** Includes the resource type (e.g., `books/`) in the ID, preventing ID-mixing bugs.
* **Checksum Validation:** The final character is a `mod-37` checksum. The `parse` method automatically validates this, instantly catching typos or copy-paste errors.
* **Crockford's Base32 Encoding:** Uses a highly readable, URL-safe character set specifically designed to avoid letters that are commonly misread by humans (i.e. no `I`, `L`, `O`).
* **Friendly Parsing:** The parser is case-insensitive, ignores hyphens thus allowing you the opportunity to make identifiers more human readable without any technical trade-offs.
* **Hierarchical Support:** Natively supports parent-child relationships (e.g., `books/1/pages/2`).
* **Database Friendly:** Easily exports to `Uint8List` (for `BINARY`) or `BigInt` (for `BIGINT`) for efficient database storage.
* **Secure Generation:** Uses a cryptographically secure random number generator by default.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  resource_id: ^1.0.0 # Check pub.dev for latest version
```

Then, import the package in your Dart file:

```dart
import 'package:resource_id/resource_id.dart';
```

## Usage
Here are several common examples of how to use the `ResourceId` class.

### 1. Generate a new ID
Use `ResourceId.generate()` to create a new, secure identifier.

```dart
// Generate a new ID for a "books" collection
final newBookId = ResourceId.generate(resourceType: 'books');

// The toString() method includes the type prefix and checksum
print(newBookId);
// Output: books/64S36D1N6RVKGE9GC5H66~
```

### 2. Parse and Validate an ID
Use `ResourceId.parse()` to convert a string back into a `ResourceId`. The checksum is validated automatically.

```dart
final idString = 'books/KFV1B65P8Q3CMC';
final id = ResourceId.parse(idString);

print(id.resourceType); // Output: books
print(id.parent);       // Output: null
```

### 3. Detect Typos with Checksums
If you parse an ID with a typo, the checksum will fail, and a `FormatException` will be thrown. This prevents you from querying your database with a malformed ID.

```dart
try {
  // Note the typo: 'P' was mistyped as 'A'
  final badId = 'books/KFV1B65A8Q3CMC'; 
  ResourceId.parse(badId);
} on FormatException catch (e) {
  print(e);
  // Output: FormatException: Invalid identifier: Checksum mismatch. Possible typo.
}
```

### 4. Use the "Friendly" Parser
The parser handles common user mistakes, like hyphens for readability or mixed case.

```dart
// This messy, human-typed ID...
final messyId = 'books/ahm6-a83h-enmp~';

// ...is parsed, normalized, and validated perfectly.
final id = ResourceId.parse(messyId);

print(id); // Output: books/AHM6A83HENMP~
```

### 5. Create Hierarchical IDs
The `ResourceId` class natively handles parent-child relationships.

```dart
// 1. Create the parent ID
final bookId = ResourceId.parse('books/AHM6A83HENMP~');

// 2. Generate a child ID, passing the parent
final pageId = ResourceId.generate(
  resourceType: 'pages',
  parent: bookId,
);

// 3. The full path is included in the ID
print(pageId); 
// Output: books/AHM6A83HENMP~/pages/RBY538159M06P4YXT~
```

### 6. Store in a Database
While the `toString()` value is great for transport or in a key-value database, you can store the raw bytes in databases like MySQL and Postgres for further efficiency.

```dart
final id = ResourceId.generate(resourceType: 'users');

// For BINARY or BLOB columns:
final Uint8List bytesToStore = id.bytes;

// For BIGINT columns (if using 8-byte IDs):
final BigInt intToStore = id.asBigInt;

// For Key Value database
String String stringToStore = id.canonicalValue;
```