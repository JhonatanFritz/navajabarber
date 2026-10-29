import 'package:flutter/material.dart';

// Texto, ícono y color de cada estado de una cita. Lo usan la tarjeta de la
// lista y la pantalla de detalle, para que siempre coincidan.
class AppointmentStatus {
  final String label;
  final IconData icon;
  final Color color;

  const AppointmentStatus._(this.label, this.icon, this.color);

  factory AppointmentStatus.from(String estado) {
    switch (estado) {
      case 'confirmada':
        return const AppointmentStatus._(
            'Confirmada', Icons.check_circle, Colors.green);
      case 'vencida':
        return AppointmentStatus._(
            'Cita vencida', Icons.history, Colors.grey.shade600);
      case 'cancelada':
        return const AppointmentStatus._('Cancelada', Icons.cancel, Colors.red);
      case 'atendida':
        return const AppointmentStatus._(
            'Atendida', Icons.done_all, Colors.blue);
      case 'no_asistio':
        return const AppointmentStatus._(
            'No asististe', Icons.event_busy, Colors.deepOrange);
      case 'no_atendida':
        return const AppointmentStatus._(
            'No atendida', Icons.warning_amber_rounded, Colors.orange);
      default:
        return AppointmentStatus._(estado, Icons.help_outline, Colors.grey);
    }
  }
}