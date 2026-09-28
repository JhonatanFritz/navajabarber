import 'package:flutter/material.dart';

class BarberHomeScreen extends StatelessWidget {
  const BarberHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi agenda')),
      body: const Center(
        child: Text('Aquí verás tu agenda del día'),
      ),
    );
  }
}