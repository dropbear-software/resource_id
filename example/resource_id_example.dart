import 'package:resource_id/resource_id.dart';

void main() {
  final newBookId = ResourceId.generate(resourceType: 'books');

  // The toString() method includes the type prefix and checksum
  print(newBookId);
  print(newBookId.resourceType);
  print(newBookId.canonicalValue);
}
