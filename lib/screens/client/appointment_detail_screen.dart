import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../services/booking_service.dart';
import '../../utils/appointment_status.dart';
import '../../utils/date_formatter.dart';
import 'booking/select_datetime_screen.dart';
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

  Future<void> _confirmAndCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar esta cita?'),
        content: Text(
          'Si cancelas tu cita, perderás el anticipo de '
          'S/ ${PaymentService.depositoReserva.toStringAsFixed(0)}. '
          '¿Quieres cancelar de todos modos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mantener cita'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cancelar de todos modos',
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

  Future<void> _reschedule() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDateTimeScreen(reschedule: _appointment),
      ),
    );
    // Si se reprogramó, volvemos a la lista: ahí se ve la cita con su nuevo horario.
    if (done == true && mounted) Navigator.of(context).pop();
  }

  String? _reprogramarBloqueadoMotivo(Appointment a) {
    if (a.estado != 'confirmada') return null;
    if (a.reprogramada) {
      return 'Ya reprogramaste esta cita una vez. No se puede volver a reprogramar.';
    }
    if (!a.puedeReprogramar) {
      return 'Ya no puedes reprogramar esta cita. Solo se puede reprogramar hasta 3 horas antes.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final a = _appointment;
    final bloqueo = _reprogramarBloqueadoMotivo(a);
    final estado = AppointmentStatus.from(a.estado);

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
                      : (a.estado == 'confirmada'
                          ? 'Reserva confirmada'
                          : estado.label),
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
              if (a.reprogramada && a.fechaOriginalTexto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Reprogramada (antes: ${a.fechaOriginalTexto} ${a.horaOriginal ?? ''})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),

              const SizedBox(height: 24),
              const Text(
                'Estado',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(estado.icon, size: 20, color: estado.color),
                  const SizedBox(width: 10),
                  Text(
                    estado.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: estado.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Spacer(),
              if (a.estado == 'confirmada') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (bloqueo != null || _cancelling) ? null : _reschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B5CF0),
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Reprogramar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (bloqueo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        bloqueo,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
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
                            'Cancelar cita',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}