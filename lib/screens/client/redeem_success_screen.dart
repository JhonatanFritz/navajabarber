import 'package:flutter/material.dart';

class RedeemSuccessScreen extends StatefulWidget {
  const RedeemSuccessScreen({super.key});

  @override
  State<RedeemSuccessScreen> createState() => _RedeemSuccessScreenState();
}

class _RedeemSuccessScreenState extends State<RedeemSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17B3A3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.card_giftcard, color: Colors.white, size: 72),
            SizedBox(height: 24),
            Text('¡Felicidades!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('El canje fue exitoso', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}