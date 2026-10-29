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

  // Reprogramación (una sola vez, hasta 3 horas antes)
  final bool reprogramada;
  final String? fechaOriginalTexto;
  final String? horaOriginal;

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
    this.reprogramada = false,
    this.fechaOriginalTexto,
    this.horaOriginal,
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
      reprogramada: data['reprogramada'] == true,
      fechaOriginalTexto: data['fechaOriginalTexto'],
      horaOriginal: data['horaOriginal'],
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
      'reprogramada': reprogramada,
      'creadoEn': FieldValue.serverTimestamp(),
    };
  }

  /// Momento de inicio de la cita (fecha + hora "HH:mm"), en hora del dispositivo.
  DateTime get inicio {
    final parts = hora.split(':');
    final h = parts.length > 1 ? int.tryParse(parts[0]) ?? 0 : 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(fecha.year, fecha.month, fecha.day, h, m);
  }

  /// Se puede reprogramar si está confirmada, no se reprogramó antes
  /// y faltan al menos 3 horas.
  bool get puedeReprogramar =>
      estado == 'confirmada' &&
      !reprogramada &&
      inicio.difference(DateTime.now()) >= const Duration(hours: 3);

  /// Estado para mostrar: una cita "confirmada" cuya hora ya pasó (más los
  /// 15 minutos de tolerancia) y que nadie marcó se muestra como "vencida".
  /// No cambia nada en la base de datos; solo es cómo se ve.
  String get estadoEfectivo {
    if (estado == 'confirmada' &&
        DateTime.now().isAfter(inicio.add(const Duration(minutes: 15)))) {
      return 'vencida';
    }
    return estado;
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
      reprogramada: reprogramada,
      fechaOriginalTexto: fechaOriginalTexto,
      horaOriginal: horaOriginal,
    );
  }
}