import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String clienteId;
  final String? barberoId;
  final String barberoNombre;
  final String? barberoEspecialidad;
  final String servicioNombre;
  final double servicioPrecio;
  final int servicioDuracion;
  final DateTime fecha;
  final String hora;
  final String estado;

  const Appointment({
    required this.id,
    required this.clienteId,
    required this.barberoId,
    required this.barberoNombre,
    this.barberoEspecialidad,
    required this.servicioNombre,
    required this.servicioPrecio,
    required this.servicioDuracion,
    required this.fecha,
    required this.hora,
    required this.estado,
  });

  factory Appointment.fromMap(String id, Map<String, dynamic> data) {
    return Appointment(
      id: id,
      clienteId: data['clienteId'] ?? '',
      barberoId: data['barberoId'],
      barberoNombre: data['barberoNombre'] ?? 'Cualquier profesional',
      barberoEspecialidad: data['barberoEspecialidad'],
      servicioNombre: data['servicioNombre'] ?? '',
      servicioPrecio: (data['servicioPrecio'] ?? 0).toDouble(),
      servicioDuracion: data['servicioDuracion'] ?? 0,
      fecha: (data['fecha'] as Timestamp).toDate(),
      hora: data['hora'] ?? '',
      estado: data['estado'] ?? 'confirmada',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'barberoId': barberoId,
      'barberoNombre': barberoNombre,
      'barberoEspecialidad': barberoEspecialidad,
      'servicioNombre': servicioNombre,
      'servicioPrecio': servicioPrecio,
      'servicioDuracion': servicioDuracion,
      'fecha': Timestamp.fromDate(fecha),
      'hora': hora,
      'estado': estado,
      'creadoEn': FieldValue.serverTimestamp(),
    };
  }

  // Crea una copia con el estado cambiado, sin tocar el resto de los datos
  Appointment copyWithEstado(String nuevoEstado) {
    return Appointment(
      id: id,
      clienteId: clienteId,
      barberoId: barberoId,
      barberoNombre: barberoNombre,
      barberoEspecialidad: barberoEspecialidad,
      servicioNombre: servicioNombre,
      servicioPrecio: servicioPrecio,
      servicioDuracion: servicioDuracion,
      fecha: fecha,
      hora: hora,
      estado: nuevoEstado,
    );
  }
}