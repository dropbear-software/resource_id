/// Calculates the modulo-37 checksum for the given bytes.
///
/// Treats the byte sequence as a large integer.
int calculateChecksum(List<int> bytes) {
  if (bytes.isEmpty) return 0;

  // Convert bytes to BigInt to handle arbitrary length
  final hexString = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  final intValue = BigInt.parse(hexString, radix: 16);

  return (intValue % BigInt.from(37)).toInt();
}

/// Returns the checksum character for the given value (0-36).
///
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U
String getChecksumCharacter(int value) {
  const alphabet = r'0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U';
  if (value < 0 || value >= alphabet.length) {
    throw RangeError('Checksum value must be between 0 and 36, inclusive.');
  }
  return alphabet[value];
}

/// Returns the numeric value of a checksum character.
///
/// Returns -1 if invalid.
int getChecksumValue(String char) {
  const alphabet = r'0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U';
  // Checksum characters are case-insensitive.
  return alphabet.indexOf(char.toUpperCase());
}
