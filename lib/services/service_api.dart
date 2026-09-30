import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';

class ServiceApi {
  static const _url = 'https://dummyjson.com/products?limit=10';

  // TODO: reemplazar por datos reales desde Firestore
  static const Map<ServiceCategory, List<String>> _includesByCategory = {
    ServiceCategory.barba: ['Perfilado', 'Navaja', 'Contornos', 'Acabado'],
    ServiceCategory.peinados: ['Lavado', 'Secado', 'Peinado', 'Fijación'],
    ServiceCategory.cortes: ['Consulta', 'Corte', 'Degradado', 'Acabado'],
  };

  static Future<List<Service>> fetchSampleServices() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los servicios (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>;

    return List.generate(products.length, (index) {
      final item = products[index] as Map<String, dynamic>;
      final category = ServiceCategory.values[index % ServiceCategory.values.length];
      final images = (item['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [item['thumbnail']?.toString() ?? ''];

      return Service(
        id: item['id'].toString(),
        name: item['title'] ?? 'Servicio',
        description: item['description'] ?? '',
        price: (item['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: 20 + (index % 4) * 10,
        category: category,
        imageUrl: item['thumbnail'] ?? '',
        images: images,
        includes: _includesByCategory[category]!,
      );
    });
  }
}