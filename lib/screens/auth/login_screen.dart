import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../client/client_shell_screen.dart';
import 'barber_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color _purple = Color(0xFF5B3EF5);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Fondo con imagen + capa oscura para legibilidad ---
          Image.asset(
            'assets/images/login_background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[850]),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),

          // --- Contenido ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'Agenda tu corte',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B3EF5),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'sin complicaciones',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),

                  // Botón de Google
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final user = await authService.signInWithGoogle();
                        if (user != null && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClientShellScreen(),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            height: 32,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 32),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () async {
                        final user = await authService.signInWithGoogle();
                        if (user != null && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClientShellScreen(),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        '¿Eres barbero? Inicia sesión aquí.',
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Texto legal
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                        children: [
                          TextSpan(text: 'Al continuar aceptas '),
                          TextSpan(
                            text: 'nuestros Términos del servicio',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'Política de privacidad.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
