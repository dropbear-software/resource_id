import 'package:resource_id/resource_id.dart';

void main() {
  print('--- Generating Identifiers ---');
  // 1. Simple Generation
  final userId = ResourceId.generate(type: 'users');
  print('Generated User ID: $userId');
  print('  Type: ${userId.type}');
  print('  Raw Bytes: ${userId.bytes}');
  print('  Checksum Char: ${userId.checksumChar}');

  // 2. Custom Length (e.g., shorter ID for internal use)
  final shortId = ResourceId.generate(byteLength: 5);
  print('Short ID: $shortId');

  print('\n--- Parsing & Validation ---');
  // 3. Parsing valid input
  try {
    // Note: Hyphens are ignored, casing is flexible
    final input = 'users/sap-85-YQD-F46G-2bhFW5N7K4DJD';

    // Let's parse the userId we just generated to be sure
    final parsed = ResourceId.parse(userId.toString());
    final isValid = ResourceId.isValid(input);
    print('Parsed ID successfully: $parsed');
    print('  Equality Check: ${parsed == userId ? "Matches" : "Mismatch"}');
    print('  Case Insensitive Check Passes: $isValid');
  } catch (e) {
    print('Error parsing: $e');
  }

  // 4. Handling Invalid Input
  const invalidInput = 'users/0123-invalid-checksum';
  try {
    ResourceId.parse(invalidInput);
  } catch (e) {
    print('Caught expected error for invalid input: $e');
  }

  print('\n--- Hierarchical Paths ---');
  // 5. Hierarchical context
  // Scenario: A comment on a specific post
  final postId = ResourceId.generate(type: 'posts');
  final commentId = ResourceId.generate();

  // Construct the path
  final commentPath = '$postId/comments/$commentId';
  print('Full Path: $commentPath');

  // Parse back
  final parsedComment = ResourceId.parse(commentPath);
  print('Parsed Comment ID Payload: ${parsedComment.toString()}');
  // The 'type' will capture the context
  print('Context (Type): ${parsedComment.type}');
}
