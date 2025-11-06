## 0.1.0

- **feature**: Initial release of the `resource_id` package.
- **feature**: Generate secure, prefixed, and checksum-validated resource identifiers using `ResourceId.generate()`.
- **feature**: Parse and validate identifiers from their full string representation with `ResourceId.parse()`.
- **feature**: Natively support hierarchical (parent-child) identifiers.
- **feature**: Provide multiple database-friendly serialization and reconstruction methods:
  - `asBigInt` and `fromBigInt` for `BIGINT` database columns.
  - `bytes` and `fromBytes` for `BINARY` or `BLOB` columns.
  - `value` and `fromValue` for key-value stores.
- **feature**: Use Crockford's Base32 encoding for improved readability and URL safety.
