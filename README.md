# ResourceId

A Dart package for creating, parsing, and validating robust, immutable, and URL-safe resource identifiers.

This package provides an immutable `ResourceId` class that enforces modern API design principles. It generates prefixed, URL-safe identifiers (e.g., `books/9V233V10702ETQW3S1WKTZ~`) that are easy to read, copy, and debug, with built-in checksums to prevent typos.

This implementation is based on the strong recommendations for great resource identifiers in the book [API Design Patterns](httpss://www.apidesignpatterns.io/) by J.J Geewax.

## Why use ResourceId?

While it can be tempting to use simple `String`s or `UUID`s for identifiers, they often fall short in real-world applications. This package solves common problems by providing IDs that are:

- **Type-Safe:** Prevents you from accidentally using a `userId` where a `bookId` was expected.
- **Prefix-Aware:** The resource type is part of the ID (e.g., `books/...`), making debugging and logging much clearer.
- **Typo-Proof:** A built-in checksum immediately catches typos or copy-paste errors during parsing, preventing invalid queries.
- **Human-Readable:** Uses Crockford's Base32, an encoding designed to avoid ambiguous characters (like `I`, `L`, `O`, and `U`), making IDs easier for humans to read and transcribe.

## Features

- **Immutable & Type-Safe:** Enforces correctness at compile time.
- **Prefix-Aware:** Includes the resource type (e.g., `books/`) in the ID, preventing ID-mixing bugs.
- **Checksum Validation:** The final character is a `mod-37` checksum. The `parse` method automatically validates this.
- **Crockford's Base32 Encoding:** Uses a highly readable, URL-safe character set.
- **Friendly Parsing:** The parser is case-insensitive and ignores hyphens, allowing for more human-readable formats like `books/bkb3-xyt4-65kz-69`.
- **Hierarchical Support:** Natively supports parent-child relationships (e.g., `books/1/pages/2`).
- **Database-First Serialization:** Easily and efficiently serialize to `Uint8List` (for `BINARY`), `BigInt` (for `BIGINT`), or a pure `String` (for key-value stores) and reconstruct with confidence.
- **Secure Generation:** Uses a cryptographically secure random number generator.

## Getting Started

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

### 1. Generating a New ID
Use `ResourceId.generate()` to create a new, secure identifier. The default size of 8 bytes is recommended for most resources as it fits perfectly in a database `BIGINT` column.

```dart
// Generate a new ID for a "books" collection
final bookId = ResourceId.generate(resourceType: 'books');

// The toString() method includes the type prefix and checksum
print(bookId);
// Output: books/8A1B2C3D4E5F6G7H8J~ (random part will vary)
```

### 2. Parsing and Validating an ID
Use `ResourceId.parse()` to convert a string back into a `ResourceId`. The checksum is validated automatically, throwing a `FormatException` if there's a typo.

```dart
try {
  // Note the typo: 'P' was mistyped as 'A'
  final badId = 'books/BKB3XYT465KZ6A'; 
  ResourceId.parse(badId);
} on FormatException catch (e) {
  print(e.message);
  // Output: Invalid identifier: Checksum mismatch. Possible typo.
}
```

### 3. Creating Hierarchical IDs
Pass the `parent` ID during generation to create a child resource.

```dart
// 1. Create the parent ID
final bookId = ResourceId.parse('books/BKB3XYT465KZ69');

// 2. Generate a child ID, passing the parent
final pageId = ResourceId.generate(
  resourceType: 'pages',
  parent: bookId,
);

// 3. The full path is included in the ID
print(pageId); 
// Output: books/BKB3XYT465KZ69/pages/3N18Y6V9T0A2W4S~
```

### 4. Storing in a Database
`ResourceId` provides multiple ways to get the raw identifier for efficient storage.

#### Option A: Relational Database (BIGINT)
This is the most performant option for relational databases, as they are highly optimized for indexing and joining on integer types.

```dart
final id = ResourceId.generate(resourceType: 'users', sizeInBytes: 8);

// Store in a BIGINT column
final BigInt intToStore = id.asBigInt;

// Reconstruct from the database value
final reconstructedId = ResourceId.fromBigInt(
  resourceType: 'users',
  value: intToStore,
  sizeInBytes: 8, // Provide the known, fixed size for this resource type
);
```

#### Option B: Relational Database (BINARY)
This is the best choice for IDs larger than 8 bytes (64 bits).

```dart
final id = ResourceId.generate(resourceType: 'sessions', sizeInBytes: 16);

// Store in a BINARY(16) or BLOB column
final Uint8List bytesToStore = id.bytes;

// Reconstruct from the database value
final reconstructedId = ResourceId.fromBytes(
  resourceType: 'sessions',
  bytes: bytesToStore,
);
```

#### Option C: Key-Value Store (String)
For databases like Firestore or DynamoDB, you can store the pure Base32 value.

```dart
final id = ResourceId.generate(resourceType: 'invoices');

// Store in a string field
final String valueToStore = id.value;

// Reconstruct from the database value
final reconstructedId = ResourceId.fromValue(
  resourceType: 'invoices',
  value: valueToStore,
);
```
