import 'package:cloud_firestore/cloud_firestore.dart';

class PointsTransaction {
  final String id;
  final String description; // ej: "Barba Italiana"
  final String subtitle; // ej: "Cita completada", "Recompensa canjeada"
  final int points; // positivo si se ganó, negativo si se gastó
  final DateTime fecha;

  const PointsTransaction({
    required this.id,
    required this.description,
    required this.subtitle,
    required this.points,
    required this.fecha,
  });

  factory PointsTransaction.fromMap(String id, Map<String, dynamic> data) {
    return PointsTransaction(
      id: id,
      description: data['descripcion'] ?? '',
      subtitle: data['subtitulo'] ?? '',
      points: data['puntos'] ?? 0,
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }
}