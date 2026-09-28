import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'services_tab.dart';
import 'notifications_tab.dart';
import 'client_home_screen.dart';

class ClientShellScreen extends StatefulWidget {
  const ClientShellScreen({super.key});

  @override
  State<ClientShellScreen> createState() => _ClientShellScreenState();
}

class _ClientShellScreenState extends State<ClientShellScreen> {
  int _selectedIndex = 0;

  void _goToHomeTab() {
    setState(() => _selectedIndex = 0);
  }

  // Ya NO puede ser 'const' porque ServicesTab y NotificationsTab
  // ahora reciben una función (_goToHomeTab), que no es un valor constante.
  List<Widget> get _tabs => [
      const HomeTab(),
      ServicesTab(onBack: _goToHomeTab),
      NotificationsTab(onBack: _goToHomeTab),
      ClientHomeScreen(onBack: _goToHomeTab),
    ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene viva cada pestaña (no se reinicia al cambiar de tab)
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        iconSize: 32,
        selectedItemColor: const Color(0xFF5B3EF5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}