import 'package:flutter/material.dart';
import '../../models/points_transaction_model.dart';
import '../../services/points_service.dart';
import '../../utils/date_formatter.dart';

class PointsHistoryScreen extends StatelessWidget {
  const PointsHistoryScreen({super.key});

  static const Color _teal = Color(0xFF17B3A3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Historial de puntos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: _teal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BARBER CLUB',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  StreamBuilder<int>(
                    stream: PointsService().streamMyPoints(),
                    builder: (context, snapshot) {
                      final points = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('$points',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<PointsTransaction>>(
                stream: PointsService().streamMyTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar el historial: ${snapshot.error}'));
                  }

                  final transactions = snapshot.data ?? [];
                  if (transactions.isEmpty) {
                    return Center(
                      child: Text('Aún no tienes movimientos de puntos',
                          style: TextStyle(color: Colors.grey[600])),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isPositive = t.points >= 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.description,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Text(t.subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              Text(
                                DateFormatter.longDate(t.fecha),
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _teal),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}${t.points}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.monetization_on, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}