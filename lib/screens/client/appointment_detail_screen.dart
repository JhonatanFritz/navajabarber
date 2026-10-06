import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../services/booking_service.dart';
import '../../utils/date_formatter.dart';
import 'cancel_success_screen.dart';
import '../../services/payment_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Appointment _appointment;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'confirmada':
        return 'Confirmada';
      case 'atendida':
        return 'Atendida';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'atendida':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmAndCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar esta reserva?'),
        content: Text(
          'Esta acción no se puede deshacer. El depósito de '
          'S/ ${PaymentService.depositoReserva.toStringAsFixed(2)} que pagaste '
          'no se devuelve al cancelar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await BookingService().cancelAppointment(_appointment.id);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CancelSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo cancelar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _appointment;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Detalle de reserva',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  a.estado == 'cancelada'
                      ? 'Reserva cancelada'
                      : 'Reserva confirmada',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCD3FB)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'S/ ${a.servicioPrecio.toStringAsFixed(0)} . ${a.servicioDuracion} min',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF5B3EF5),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              a.barberoNombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (a.barberoEspecialidad != null)
                              Text(
                                a.barberoEspecialidad!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Fecha y hora',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 20,
                    color: Color(0xFF5B3EF5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormatter.longDate(a.fecha),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: Color(0xFF5B3EF5),
                  ),
                  const SizedBox(width: 10),
                  Text(a.hora, style: const TextStyle(fontSize: 14)),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Estado',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: _estadoColor(a.estado),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _estadoLabel(a.estado),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const Spacer(),
              if (a.estado == 'confirmada')
                Center(
                  child: TextButton(
                    onPressed: _cancelling ? null : _confirmAndCancel,
                    child: _cancelling
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Cancelar reserva',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
