import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/appointment_model.dart';
import '../../../models/barber_model.dart';
import '../../../models/service_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/payment_service.dart';
import '../../../utils/date_formatter.dart';
import 'booking_success_screen.dart';
import 'yape_payment_screen.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Service service;
  final Barber? barber;
  final DateTime date;
  final String time;

  const ConfirmBookingScreen({
    super.key,
    required this.service,
    required this.barber,
    required this.date,
    required this.time,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return; // evita doble toque

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    // 1. Primero el pago del depósito.
    final payment = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (context) => YapePaymentScreen(
          email: user?.email ?? '',
          description: '${widget.service.name} - reserva',
        ),
      ),
    );

    // Si cancela o el pago falla, no se crea ninguna cita.
    if (payment == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    // 2. Pago exitoso: se crea la cita con los datos del depósito.
    final appointment = Appointment(
      id: '',
      clienteId: uid,
      barberoId: widget.barber?.id,
      barberoNombre: widget.barber?.name ?? 'Cualquier profesional',
      barberoEspecialidad: widget.barber?.specialty,
      servicioNombre: widget.service.name,
      servicioPrecio: widget.service.price,
      servicioDuracion: widget.service.durationMinutes,
      fecha: widget.date,
      fechaTexto: DateFormatter.isoDate(widget.date),
      hora: widget.time,
      estado: 'confirmada',
      depositoPagado: true,
      depositoMonto: payment.amount,
      pagoId: payment.chargeId,
      pagoSimulado: payment.simulated,
    );

    try {
      await BookingService().createAppointment(appointment);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo confirmar la reserva: $e')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookingSuccessScreen()),
      );
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5B3EF5)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: style.copyWith(color: bold ? Colors.black : Colors.grey[700]),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.service.price;
    const deposit = PaymentService.depositoReserva;
    final balance = price > deposit ? price - deposit : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 24),
                    ),
                    const SizedBox(width: 4),
                    const Text('Agendar',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                const Center(
                  child: Text('Confirma tu reserva',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text('Revisa los detalles antes de confirmar',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.content_cut, widget.service.name),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          'S/ ${price.toStringAsFixed(0)} . ${widget.service.durationMinutes} min',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ),
                      _infoRow(Icons.person_outline,
                          widget.barber?.name ?? 'Cualquier profesional'),
                      _infoRow(Icons.event_available, DateFormatter.longDate(widget.date)),
                      _infoRow(Icons.access_time, widget.time),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Resumen',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _summaryRow('Servicio', 'S/ ${price.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _summaryRow('Depósito (lo pagas ahora con Yape)',
                    '- S/ ${deposit.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _summaryRow('Saldo a pagar en el local',
                    'S/ ${balance.toStringAsFixed(2)}',
                    bold: true),

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Text(
                    'Para confirmar la reserva pagarás ahora un depósito de '
                    'S/ ${deposit.toStringAsFixed(2)} con Yape, que se descuenta del '
                    'precio del servicio. Si no asistes o cancelas la cita, '
                    'el depósito no se devuelve.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Confirmar reserva',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}