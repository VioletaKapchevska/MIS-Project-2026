class Pet{
  final String id;
  final int age;
  final String breed;
  final String name;
  final String ownerId;
  final String type;
  final int weight;
  final String imgUrl;

  Pet({
    required this.id,
    required this.age,
    required this.breed,
    required this.name,
    required this.ownerId,
    required this.type,
    required this.weight,
    required this.imgUrl,
});

  factory Pet.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Pet(
      id: documentId,
      age: (data['age'] ?? 0).toInt(),
      breed: data['breed'] ?? '',
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      type: data['type'] ?? '',
      weight: (data['weight'] ?? 0).toInt(),
      imgUrl: data['imageUrl'] ?? '',
    );
  }

}