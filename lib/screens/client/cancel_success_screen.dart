import 'package:flutter/material.dart';
import 'my_appointments_screen.dart';

class CancelSuccessScreen extends StatefulWidget {
  const CancelSuccessScreen({super.key});

  @override
  State<CancelSuccessScreen> createState() => _CancelSuccessScreenState();
}

class _CancelSuccessScreenState extends State<CancelSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
        (route) => route.isFirst, // borra el detalle y deja solo el shell base
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1465A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, color: Colors.white, size: 72),
            const SizedBox(height: 24),
            const Text('¡Reserva cancelada!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tu cita ha sido cancelada correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}