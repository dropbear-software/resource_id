# Gemini Code Understanding

## Project Overview

This project is a Dart library named `resource_id`. Its purpose is to provide a robust and immutable solution for creating, parsing, and validating resource identifiers, guided by modern API design principles.

The core of the library is the `ResourceId` class, which is immutable and provides methods for generating new IDs, parsing from strings, and serializing to various formats for database storage (including `BigInt` for relational databases and `String` for key-value stores).

## Design Philosophy

The design of this library is based on a set of principles for creating "good" identifiers that are easy to use, unique, permanent, and secure.

*   **Uniqueness and Scoping**: To prevent identifier collisions between different types of resources (e.g., a book and a user having the same ID), the library uses **type-safe prefixes** (e.g., `books/` or `users/`). This creates a unique namespace for each resource type, ensuring that an ID is unambiguous.

*   **Readability and Shareability**: Identifiers should be easy for humans to read, share, and type. To achieve this, the library uses **Crockford's Base32 encoding**. This encoding avoids visually ambiguous characters (like `1`, `I`, and `L`, or `0` and `O`) and is case-insensitive, making it resilient to common transcription errors. It also avoids characters that have special meaning in URIs.

*   **Error Detection**: To help distinguish between a valid identifier that points to a non-existent resource and an identifier that has been mistyped, each `ResourceId` includes a **checksum**. This allows for immediate validation that the ID is structurally correct, improving the robustness of APIs that use it.

*   **Permanence and Immutability**: A resource identifier should be permanent and never change once assigned. The `ResourceId` class is immutable to enforce this principle. The library is designed to generate identifiers that should never be reused, even after a resource is deleted (a practice known as "tomb-stoning").

*   **Unpredictability**: To enhance security, identifiers should not be sequential or predictable. The library generates identifiers from a large, random keyspace, making it difficult for attackers to guess valid IDs and probe for vulnerabilities.

The project is well-documented, with a detailed `README.md` that explains the rationale and usage, and the source code itself contains clear documentation comments.

## Building and Running

This is a Dart library, so there is no main executable to run. The primary way to interact with the project is by running its tests.

### Running Tests

The project uses the standard `test` package for testing. To run the tests, use the following command:

```bash
dart test
```

## Development Conventions

### Coding Style

The project follows standard Dart conventions and uses the `lints` package to enforce code quality. The `analysis_options.yaml` file includes the recommended lints from `package:lints/recommended.yaml`. It also includes a large number of additional lints beyond what is typically recommended to enforce a higher code quality with stricter standards.

### Testing

The project has a comprehensive test suite in the `test/` directory. The tests are written using the `test` package and follow a clear "arrange, act, assert" pattern within `group` and `test` blocks. The tests cover:
- ID generation and parsing
- Checksum validation and typo detection
- "Friendly" parsing (case-insensitivity, ignoring hyphens)
- Hierarchical ID creation and parsing
- Equality checks
- Serialization and deserialization for different database types

### Dependencies

- `base32_codec`: Used for Crockford's Base32 encoding and decoding.
- `meta`: Used for annotations like `@immutable`.

Development dependencies include `lints` for static analysis and `test` for unit testing. Dependencies are managed in the `pubspec.yaml` file.
