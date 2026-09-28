class Barber {
  final String id;
  final String name;
  final String specialty;
  final String photoUrl;
  final double rating; // 0.0 a 5.0

  const Barber({
    required this.id,
    required this.name,
    required this.specialty,
    required this.photoUrl,
    required this.rating,
  });

  // Cuando conectemos Firestore, armamos el objeto desde el documento así:
  factory Barber.fromMap(String id, Map<String, dynamic> data) {
    return Barber(
      id: id,
      name: data['nombre'] ?? '',
      specialty: data['especialidad'] ?? '',
      photoUrl: data['fotoUrl'] ?? '',
      rating: (data['calificacion'] ?? 0).toDouble(),
    );
  }
}