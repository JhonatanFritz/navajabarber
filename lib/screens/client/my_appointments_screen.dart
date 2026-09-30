import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/appointment_card.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  bool _showUpcoming = true;

  Widget _buildTabChip(String label, IconData icon, bool isUpcomingTab) {
    final isSelected = _showUpcoming == isUpcomingTab;
    return GestureDetector(
      onTap: () => setState(() => _showUpcoming = isUpcomingTab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                )),
          ],
        ),
      ),
    );
  }

  // Una cita es "próxima" solo si está confirmada Y su fecha aún no pasó.
  // Cualquier otro caso (cancelada, atendida, o confirmada pero ya pasada) va a historial.
  bool _isUpcoming(Appointment a, DateTime today) {
    return a.estado == 'confirmada' && !a.fecha.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Mis citas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildTabChip('Próximas', Icons.access_time, true),
                  const SizedBox(width: 10),
                  _buildTabChip('Historial', Icons.calendar_month, false),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<List<Appointment>>(
                  stream: BookingService().streamMyAppointments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error al cargar tus citas: ${snapshot.error}'));
                    }

                    final all = snapshot.data ?? [];

                    final upcoming = all.where((a) => _isUpcoming(a, today)).toList();
                    final historial = all.where((a) => !_isUpcoming(a, today)).toList()
                      ..sort((a, b) => b.fecha.compareTo(a.fecha)); // más reciente primero

                    final appointments = _showUpcoming ? upcoming : historial;

                    if (appointments.isEmpty) {
                      return Center(
                        child: Text(
                          _showUpcoming ? 'No tienes citas próximas' : 'Aún no tienes historial de citas',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    if (!_showUpcoming) {
                      return ListView(
                        children: appointments.map((a) => AppointmentCard(appointment: a)).toList(),
                      );
                    }

                    final nextAppointment = appointments.first;
                    final others = appointments.skip(1).toList();

                    return ListView(
                      children: [
                        const Text('Próxima cita', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        AppointmentCard(appointment: nextAppointment, highlighted: true),
                        if (others.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('Otras citas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...others.map((a) => AppointmentCard(appointment: a)),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}