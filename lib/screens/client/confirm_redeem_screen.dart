import 'package:flutter/material.dart';
import '../../models/reward_model.dart';
import '../../services/points_service.dart';
import 'redeem_success_screen.dart';

class ConfirmRedeemScreen extends StatefulWidget {
  final Reward reward;

  const ConfirmRedeemScreen({super.key, required this.reward});

  @override
  State<ConfirmRedeemScreen> createState() => _ConfirmRedeemScreenState();
}

class _ConfirmRedeemScreenState extends State<ConfirmRedeemScreen> {
  bool _isRedeeming = false;
  String? _errorMessage;

  Future<void> _confirmRedeem() async {
    setState(() {
      _isRedeeming = true;
      _errorMessage = null;
    });

    try {
      final success = await PointsService().redeemReward(widget.reward);

      if (!success) {
        if (mounted) {
          setState(() {
            _isRedeeming = false;
            _errorMessage = 'Ya no tienes suficientes puntos para este canje.';
          });
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RedeemSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
          _errorMessage = 'No se pudo completar el canje: $e';
        });
      }
    }
  }

  Widget _buildPointsRow(String label, int points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Row(
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFF17B3A3), size: 18),
            const SizedBox(width: 6),
            Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 4),
            const Text('puntos', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

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
              final currentBalance = snapshot.data ?? 0;
              final balanceAfter = currentBalance - widget.reward.cost;
              final canAfford = currentBalance >= widget.reward.cost;

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
                      const Text('Confirmar canje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Center(
                    child: Text('Confirma tu recompensa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Revisa los detalles antes de realizar el canje',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Image.network(
                              widget.reward.imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(height: 140, color: Colors.grey[300]),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  widget.reward.name.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(widget.reward.description, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildPointsRow('Costo de la recompensa', widget.reward.cost),
                  const SizedBox(height: 10),
                  _buildPointsRow('Tu saldo actual', currentBalance),
                  const SizedBox(height: 10),
                  _buildPointsRow('Saldo después del canje', balanceAfter),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),

                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!canAfford || _isRedeeming) ? null : _confirmRedeem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5CF0),
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: _isRedeeming
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(canAfford ? 'Confirmar canje' : 'Puntos insuficientes',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}