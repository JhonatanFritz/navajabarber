import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../barber/home_barber_screen.dart';

class BarberLoginScreen extends StatefulWidget {
  const BarberLoginScreen({super.key});

  @override
  State<BarberLoginScreen> createState() => _BarberLoginScreenState();
}

class _BarberLoginScreenState extends State<BarberLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _authService.signInBarbero(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BarberHomeScreen()),
      );
    } else {
      setState(() => _errorMessage = 'Correo o contraseña incorrectos');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('Iniciar sesión'),
                  ),
          ],
        ),
      ),
    );
  }
}