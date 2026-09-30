enum ServiceCategory { barba, peinados, cortes }

class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final ServiceCategory category;
  final String imageUrl; // imagen principal, usada en las tarjetas
  final List<String> images; // galería para la pantalla de detalle
  final List<String> includes; // qué incluye el servicio

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.imageUrl,
    this.images = const [],
    this.includes = const [],
  });

  factory Service.fromMap(String id, Map<String, dynamic> data) {
    return Service(
      id: id,
      name: data['nombre'] ?? '',
      description: data['descripcion'] ?? '',
      price: (data['precio'] ?? 0).toDouble(),
      durationMinutes: data['duracionMinutos'] ?? 0,
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == data['categoria'],
        orElse: () => ServiceCategory.cortes,
      ),
      imageUrl: data['imagenUrl'] ?? '',
      images: List<String>.from(data['imagenes'] ?? []),
      includes: List<String>.from(data['incluye'] ?? []),
    );
  }
}