import 'package:flutter/material.dart';
import '../models/notification_item_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const NotificationCard({super.key, required this.notification});

  Widget _buildLeadingIcon() {
    switch (notification.type) {
      case NotificationType.points:
        return const Icon(Icons.star, color: Colors.amber, size: 32);
      case NotificationType.appointment:
      case NotificationType.general:
        return Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF5B3EF5),
            shape: BoxShape.circle,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}