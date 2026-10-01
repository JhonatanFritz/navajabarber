import 'package:cloud_firestore/cloud_firestore.dart';

class Redemption {
  final String id;
  final String clienteId;
  final String rewardName;
  final String rewardDescription;
  final int cost;
  final String estado; // 'pendiente' o 'completado'
  final DateTime fechaCanje;

  const Redemption({
    required this.id,
    required this.clienteId,
    required this.rewardName,
    required this.rewardDescription,
    required this.cost,
    required this.estado,
    required this.fechaCanje,
  });

  factory Redemption.fromMap(String id, Map<String, dynamic> data) {
    return Redemption(
      id: id,
      clienteId: data['clienteId'] ?? '',
      rewardName: data['recompensaNombre'] ?? '',
      rewardDescription: data['recompensaDescripcion'] ?? '',
      cost: data['costoPuntos'] ?? 0,
      estado: data['estado'] ?? 'pendiente',
      fechaCanje: (data['fechaCanje'] as Timestamp).toDate(),
    );
  }
}