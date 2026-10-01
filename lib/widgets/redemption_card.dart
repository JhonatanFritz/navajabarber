import 'package:flutter/material.dart';
import '../models/redemption_model.dart';
import '../utils/date_formatter.dart';

class RedemptionCard extends StatelessWidget {
  final Redemption redemption;

  const RedemptionCard({super.key, required this.redemption});

  bool get _isPending => redemption.estado == 'pendiente';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isPending ? const Color(0xFFFFD23F) : Colors.grey[300]!, width: _isPending ? 2 : 1),
      ),
      child: Row(
        children: [
          Icon(
            _isPending ? Icons.card_giftcard : Icons.check_circle,
            color: _isPending ? const Color(0xFFFFD23F) : Colors.green,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(redemption.rewardName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(redemption.rewardDescription, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(DateFormatter.longDate(redemption.fechaCanje),
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isPending ? const Color(0xFFFFF7DC) : const Color(0xFFE3F7EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isPending ? 'Pendiente' : 'Completado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _isPending ? const Color(0xFFB8860B) : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}