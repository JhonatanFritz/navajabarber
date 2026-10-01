import 'package:flutter/material.dart';
import '../../models/redemption_model.dart';
import '../../services/points_service.dart';
import '../../widgets/redemption_card.dart';

class MyRedemptionsScreen extends StatelessWidget {
  const MyRedemptionsScreen({super.key});

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
                  const Text('Mis recompensas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<List<Redemption>>(
                  stream: PointsService().streamMyRedemptions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error al cargar tus recompensas: ${snapshot.error}'));
                    }

                    final redemptions = snapshot.data ?? [];
                    if (redemptions.isEmpty) {
                      return Center(
                        child: Text('Aún no has canjeado ninguna recompensa', style: TextStyle(color: Colors.grey[600])),
                      );
                    }

                    final pending = redemptions.where((r) => r.estado == 'pendiente').toList();
                    final completed = redemptions.where((r) => r.estado != 'pendiente').toList();

                    return ListView(
                      children: [
                        if (pending.isNotEmpty) ...[
                          const Text('Pendientes de usar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...pending.map((r) => RedemptionCard(redemption: r)),
                          const SizedBox(height: 20),
                        ],
                        if (completed.isNotEmpty) ...[
                          const Text('Historial', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...completed.map((r) => RedemptionCard(redemption: r)),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}