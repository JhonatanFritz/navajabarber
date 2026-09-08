import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_barbero_screen.dart';

class BarberoLoginScreen extends StatefulWidget {
  const BarberoLoginScreen({super.key});

  @override
  State<BarberoLoginScreen> createState() => _BarberoLoginScreenState();
}

class _BarberoLoginScreenState extends State<BarberoLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _cargando = false;
  String? _errorMensaje;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    final user = await _authService.signInBarbero(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _cargando = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeBarberoScreen()),
      );
    } else {
      setState(() => _errorMensaje = 'Correo o contraseña incorrectos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso de barberos')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMensaje != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _iniciarSesion,
                    child: const Text('Iniciar sesión'),
                  ),
          ],
        ),
      ),
    );
  }
}