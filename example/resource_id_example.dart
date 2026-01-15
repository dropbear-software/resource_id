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
    // Let's parse the userId we just generated to be sure it's valid.
    final parsed = ResourceId.parse(userId.toString());
    print('Parsed generated ID successfully: $parsed');
    print('  Equality Check: ${parsed == userId ? "Matches" : "Mismatch"}');

    // Now, let's create a "messy" version of the same ID to show parsing flexibility.
    final messyString = userId.toString().toLowerCase().replaceRange(10, 10, '-');
    final parsedMessy = ResourceId.parse(messyString);
    print('Parsed messy ID successfully: $parsedMessy');
    print('  Equality Check with messy parse: ${parsedMessy == userId ? "Matches" : "Mismatch"}');
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
