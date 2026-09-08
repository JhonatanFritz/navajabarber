import 'package:flutter/material.dart';

class HomeClientScreen extends StatelessWidget {
  const HomeClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio - Cliente')),
      body: const Center(
        child: Text('Bienvenido, aquí verás tus citas'),
      ),
    );
  }
}