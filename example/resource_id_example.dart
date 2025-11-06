import 'dart:typed_data';

import 'package:resource_id/resource_id.dart';

// A simple data model for a city. In a real app, this might be a
// class from a database or an API response.
class City {
  final ResourceId id;
  final String name;
  final String country;

  City({required this.id, required this.name, required this.country});

  @override
  String toString() => 'City(id: $id, name: "$name", country: "$country")';
}

// A data model for a landmark, which is a child resource of a City.
class Landmark {
  final ResourceId id;
  final String name;

  Landmark({required this.id, required this.name}) {
    // Enforce that a landmark must have a parent.
    if (id.parent == null) {
      throw ArgumentError('Landmark ID must have a parent city.');
    }
  }

  @override
  String toString() => 'Landmark(id: $id, name: "$name")';
}

void main() {
  print('--- 1. Generating and Storing IDs ---');

  // Generate some IDs for new city resources.
  // The default size of 8 bytes (64 bits) is a great choice for storing
  // as a BIGINT in a relational database.
  final londonId = ResourceId.generate(resourceType: 'cities');
  final tokyoId = ResourceId.generate(resourceType: 'cities');

  final london = City(id: londonId, name: 'London', country: 'UK');
  final tokyo = City(id: tokyoId, name: 'Tokyo', country: 'Japan');

  // Let's simulate different database storage strategies.

  // Strategy A: Relational DB with BIGINT primary key (most performant)
  final Map<BigInt, City> citiesById_bigInt = {
    london.id.asBigInt: london,
    tokyo.id.asBigInt: tokyo,
  };

  // Strategy B: Relational DB with BINARY(8) primary key
  final Map<Uint8List, City> citiesById_bytes = {
    london.id.bytes: london,
    tokyo.id.bytes: tokyo,
  };

  // Strategy C: Key-Value DB (like DynamoDB/Firestore) with a string key
  final Map<String, City> citiesById_value = {
    london.id.value: london,
    tokyo.id.value: tokyo,
  };

  print('Stored London: ${london.id}');
  print('Stored Tokyo:  ${tokyo.id}');
  print('');

  print('--- 2. Retrieving from Storage ---');

  // When you retrieve the data, you need to reconstruct the ResourceId.
  // You provide the known, fixed information (resourceType, sizeInBytes)
  // to rebuild the full object.
  final londonBigIntFromDb = london.id.asBigInt;
  final reconstructedId = ResourceId.fromBigInt(
    resourceType: 'cities',
    value: londonBigIntFromDb,
    sizeInBytes: 8, // You know this from your application's design
  );

  final retrievedCity = citiesById_bigInt[reconstructedId.asBigInt]!;
  print('Retrieved City: $retrievedCity');
  print(
    'Original and reconstructed IDs match: ${retrievedCity.id == londonId}',
  );
  print('');

  print('--- 3. Handling Hierarchical IDs ---');

  // Now let's add a landmark that belongs to London.
  // We pass the parent ID during generation.
  final towerOfLondonId = ResourceId.generate(
    resourceType: 'landmarks',
    parent: londonId,
  );

  final tower = Landmark(id: towerOfLondonId, name: 'Tower of London');

  print('Generated Landmark ID: $towerOfLondonId');
  print('Parent ID: ${towerOfLondonId.parent}');
  print('');

  print('--- 4. Parsing and Validating IDs ---');

  // Imagine an ID comes in from an API request or a URL parameter.
  final incomingIdString = towerOfLondonId.toString();

  // You can parse it to get a structured ResourceId object.
  final parsedId = ResourceId.parse(incomingIdString);
  print('Parsed ID value: ${parsedId.value}');
  print('Parsed parent resource type: ${parsedId.parent?.resourceType}');
  print('');

  print('--- 5. Automatic Typo Detection ---');

  // What if the ID has a typo? The checksum validation will catch it.
  // Here, the final character 'V' is mistyped as 'B'.
  final badIdString = incomingIdString.replaceRange(
    incomingIdString.length - 1,
    incomingIdString.length,
    'B',
  );

  try {
    ResourceId.parse(badIdString);
  } on FormatException catch (e) {
    print('Successfully caught a typo!');
    print('Input: "$badIdString"');
    print('Error: ${e.message}');
  }
}
