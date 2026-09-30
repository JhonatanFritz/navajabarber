import 'package:flutter/material.dart';
import '../my_appointments_screen.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
        (route) => route.isFirst, // borra todo el flujo de reserva, deja solo el shell base
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17B3A3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
              child: const Icon(Icons.check, color: Colors.white, size: 72),
            ),
            const SizedBox(height: 24),
            const Text('¡Reserva confirmada!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tu cita ha sido registrada correctamente.',
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