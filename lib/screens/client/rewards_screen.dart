import 'package:flutter/material.dart';
import '../../models/reward_model.dart';
import '../../services/points_service.dart';
import '../../widgets/reward_card.dart';
import 'confirm_redeem_screen.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const List<Reward> _sampleRewards = [
    Reward(
      id: '1',
      name: 'Taper Fade',
      description: 'Un corte moderno y atrevido para quienes tienen estilo.',
      cost: 125,
      imageUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
    ),
    Reward(
      id: '2',
      name: 'Clásico',
      description: 'Un corte atemporal, prolijo y elegante para toda ocasión.',
      cost: 300,
      imageUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<int>(
            stream: PointsService().streamMyPoints(),
            builder: (context, snapshot) {
              final points = snapshot.data ?? 0;

              return Column(
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
                      const Text('Recompensas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text('Tus puntos', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFF17B3A3), size: 22),
                      const SizedBox(width: 8),
                      Text('$points', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Text('puntos', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Canjea tus puntos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _sampleRewards.length,
                      itemBuilder: (context, index) {
                        final reward = _sampleRewards[index];
                        final canAfford = points >= reward.cost;

                        return RewardCard(
                          reward: reward,
                          enabled: canAfford,
                          onRedeem: canAfford
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ConfirmRedeemScreen(reward: reward)),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}