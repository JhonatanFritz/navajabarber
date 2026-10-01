class Reward {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String imageUrl;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.imageUrl,
  });

  // Cuando conectemos Firestore, armamos el objeto desde el documento así:
  factory Reward.fromMap(String id, Map<String, dynamic> data) {
    return Reward(
      id: id,
      name: data['nombre'] ?? '',
      description: data['descripcion'] ?? '',
      cost: data['costo'] ?? 0,
      imageUrl: data['imagenUrl'] ?? '',
    );
  }
}