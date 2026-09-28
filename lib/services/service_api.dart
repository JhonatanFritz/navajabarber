import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';

class ServiceApi {
  // DummyJSON: API pública gratuita, útil para simular datos "reales" mientras
  // no tenemos la colección de servicios en Firestore lista.
  static const _url = 'https://dummyjson.com/products?limit=10';

  static Future<List<Service>> fetchSampleServices() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los servicios (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>;

    // Mapeamos cada producto de la API a nuestro modelo Service.
    // La API no maneja "duración" ni "categoría de barbería", así que esos
    // dos campos los generamos localmente solo para efectos de la demo.
    return List.generate(products.length, (index) {
      final item = products[index] as Map<String, dynamic>;
      return Service(
        id: item['id'].toString(),
        name: item['title'] ?? 'Servicio',
        description: item['description'] ?? '',
        price: (item['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: 20 + (index % 4) * 10,
        category: ServiceCategory.values[index % ServiceCategory.values.length],
        imageUrl: item['thumbnail'] ?? '',
      );
    });
  }
}