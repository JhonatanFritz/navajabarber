import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/barber_model.dart';

class BarberApi {
  // DummyJSON: endpoint de usuarios, trae fotos reales de personas + nombres
  static const _url = 'https://dummyjson.com/users?limit=10';

  // TODO: reemplazar por datos reales desde Firestore (usuarios con rol 'barbero')
  static const List<String> _specialties = [
    'Experto en barbas',
    'Peinados',
    'Cortes modernos',
    'Degradados',
    'Estilo clásico',
  ];

  static Future<List<Barber>> fetchSampleBarbers() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los profesionales (código ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>;

    return List.generate(users.length, (index) {
      final item = users[index] as Map<String, dynamic>;
      final rating = 4.0 + (index % 10) / 10; // valor simulado, entre 4.0 y 4.9

      return Barber(
        id: item['id'].toString(),
        name: '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'.trim(),
        specialty: _specialties[index % _specialties.length],
        photoUrl: item['image'] ?? '',
        rating: double.parse(rating.toStringAsFixed(1)),
      );
    });
  }
}