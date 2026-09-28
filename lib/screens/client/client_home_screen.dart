import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/profile_menu_item.dart';
import '../auth/login_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ClientHomeScreen({super.key, this.onBack});

  static const Color _teal = Color(0xFF17B3A3);
  static const Color _purple = Color(0xFF5B3EF5);

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      // pushAndRemoveUntil borra TODO el historial de navegación (incluyendo
      // el menú inferior), así el usuario no puede volver atrás con el botón
      // físico y encontrarse "logueado" por accidente.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (onBack != null) {
                        onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Mi perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // --- Foto con borde ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: _teal, width: 3)),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user?.displayName ?? 'Sin nombre',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? 'Sin correo',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),

              const SizedBox(height: 28),
              ProfileMenuItem(
                icon: Icons.person_outline,
                label: 'Datos personales',
                onTap: () {
                  // TODO: navegar a la pantalla de datos personales
                },
              ),
              ProfileMenuItem(
                icon: Icons.lock_outline,
                label: 'Contraseña',
                onTap: () {
                  // TODO: navegar al cambio de contraseña
                },
              ),
              ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Preferencias de notificaciones',
                onTap: () {
                  // TODO: navegar a preferencias de notificaciones
                },
              ),

              const SizedBox(height: 24),
              const Text('Barber club', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                    child: const Icon(Icons.star, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  // TODO: reemplazar por los puntos reales del usuario desde Firestore
                  const Text('15 puntos', style: TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  // TODO: navegar al historial de puntos
                },
                child: const Text(
                  'Ver mis puntos →',
                  style: TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),
              ProfileMenuItem(
                icon: Icons.help_outline,
                label: 'Ayuda',
                showArrow: false,
                onTap: () {
                  // TODO: navegar a ayuda
                },
              ),
              ProfileMenuItem(
                icon: Icons.description_outlined,
                label: 'Términos y condiciones',
                showArrow: false,
                onTap: () {
                  // TODO: navegar a términos y condiciones
                },
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE04B4B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}