import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime fecha;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.fecha,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['fecha'];
    return AppNotification(
      id: id,
      title: (data['titulo'] ?? '') as String,
      body: (data['cuerpo'] ?? '') as String,
      // Si por algún motivo falta la fecha, no se rompe la lista.
      fecha: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}