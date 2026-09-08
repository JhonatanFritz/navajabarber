import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_client_screen.dart';
import 'barbero_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Barbería App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión con Google'),
              onPressed: () async {
                final user = await authService.signInWithGoogle();
                if (user != null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeClientScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BarberoLoginScreen()),
                );
              },
              child: const Text('¿Eres barbero? Inicia sesión aquí'),
            ),
          ],
        ),
      ),
    );
  }
}