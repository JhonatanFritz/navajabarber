import 'package:flutter/material.dart';

import '../models/appointment_model.dart';
import '../utils/appointment_status.dart';
import '../utils/date_formatter.dart';
import '../screens/client/appointment_detail_screen.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool highlighted;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.highlighted = false,
  });

  Widget _row(IconData icon, String text, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.black54),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = AppointmentStatus.from(appointment.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? const Color(0xFF5B3EF5) : Colors.grey[300]!,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_cut, size: 18, color: Color(0xFF5B3EF5)),
              const SizedBox(width: 8),
              Text(
                appointment.servicioNombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row(
            Icons.calendar_today_outlined,
            DateFormatter.longDate(appointment.fecha),
          ),
          _row(Icons.person_outline, appointment.barberoNombre),
          _row(
            Icons.access_time,
            '${appointment.hora} . ${appointment.servicioDuracion} min',
          ),
          _row(estado.icon, estado.label, color: estado.color, bold: true),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AppointmentDetailScreen(appointment: appointment),
                ),
              );
            },
            child: const Text(
              'Ver detalles →',
              style: TextStyle(
                color: Color(0xFF5B3EF5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}