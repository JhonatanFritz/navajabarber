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
  final String? fechaTexto; // "2026-10-06"; las citas antiguas no lo tienen
  final String hora;
  final String estado;
  final bool depositoPagado;
  final double depositoMonto;
  final String? pagoId;
  final bool pagoSimulado;

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
    this.fechaTexto,
    required this.hora,
    required this.estado,
    this.depositoPagado = false,
    this.depositoMonto = 0,
    this.pagoId,
    this.pagoSimulado = false,
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
      fechaTexto: data['fechaTexto'],
      hora: data['hora'] ?? '',
      estado: data['estado'] ?? 'confirmada',
      depositoPagado: data['depositoPagado'] ?? false,
      depositoMonto: (data['depositoMonto'] ?? 0).toDouble(),
      pagoId: data['pagoId'],
      pagoSimulado: data['pagoSimulado'] ?? false,
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
      'fechaTexto': fechaTexto,
      'hora': hora,
      'estado': estado,
      'depositoPagado': depositoPagado,
      'depositoMonto': depositoMonto,
      'pagoId': pagoId,
      'pagoSimulado': pagoSimulado,
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
      fechaTexto: fechaTexto,
      hora: hora,
      estado: nuevoEstado,
      depositoPagado: depositoPagado,
      depositoMonto: depositoMonto,
      pagoId: pagoId,
      pagoSimulado: pagoSimulado,
    );
  }
}