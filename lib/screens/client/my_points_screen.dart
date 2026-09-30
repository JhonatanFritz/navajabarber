import 'package:flutter/material.dart';
import '../../services/points_service.dart';
import 'points_history_screen.dart';

class MyPointsScreen extends StatelessWidget {
  const MyPointsScreen({super.key});

  static const Color _purple = Color(0xFF5B3EF5);
  static const Color _teal = Color(0xFF17B3A3);

  // TODO: coordinar con el área administrativa los valores reales por categoría
  static const List<(String, int)> _earnRates = [
    ('Corte de cabello', 15),
    ('Barba', 18),
    ('Combo', 30),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Mis puntos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),

              StreamBuilder<int>(
                stream: PointsService().streamMyPoints(),
                builder: (context, snapshot) {
                  final points = snapshot.data ?? 0;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_purple, _teal],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text('BARBER CLUB',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1)),
                                  SizedBox(width: 4),
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('$points',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                              const Text('Puntos', style: TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(height: 6),
                              const Text(
                                '75 puntos para tu próxima recompensa', // TODO: calcular según catálogo real
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: navegar al catálogo de recompensas
                  },
                  icon: const Icon(Icons.card_giftcard, color: _purple),
                  label: const Text('Ver recompensas',
                      style: TextStyle(color: _purple, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD23F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const Center(
                child:
                    Text('¿Cómo conseguir puntos?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ..._earnRates.map(
                (rate) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('+${rate.$2}  ${rate.$1}', style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '* Los puntos se acreditan al completar tu cita',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                ),
              ),

              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PointsHistoryScreen()),
                    );
                  },
                  child: const Text('Historial de puntos →',
                      style: TextStyle(color: _purple, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}