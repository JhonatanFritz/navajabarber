import 'package:flutter/material.dart';
import '../../models/notification_item_model.dart';
import '../../widgets/notification_card.dart';

class NotificationsTab extends StatelessWidget {
  final VoidCallback? onBack;

  const NotificationsTab({super.key, this.onBack});

  // TODO: reemplazar por datos reales desde Firestore (colección 'notificaciones' del usuario)
  static const List<NotificationItem> _sampleNotifications = [
    NotificationItem(
      title: 'Tu cita está confirmada',
      subtitle: 'Barba Italiana . 10:00',
      timeAgo: 'Hace 1 hora',
      groupLabel: 'Hoy',
      type: NotificationType.appointment,
    ),
    NotificationItem(
      title: 'Tu cita está confirmada',
      subtitle: 'Barba Italiana . 10:00',
      timeAgo: 'Hace 1 hora',
      groupLabel: 'Hoy',
      type: NotificationType.appointment,
    ),
    NotificationItem(
      title: '¡Ganaste puntos!',
      subtitle: '+15 puntos por tu cita',
      timeAgo: 'Hace 17 horas',
      groupLabel: 'Ayer',
      type: NotificationType.points,
    ),
  ];

  // Agrupa la lista plana en secciones por groupLabel, manteniendo el orden original
  Map<String, List<NotificationItem>> _groupByDate(List<NotificationItem> items) {
    final Map<String, List<NotificationItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.groupLabel, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_sampleNotifications);

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
                  const Text('Notificaciones',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: grouped.entries.expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...entry.value.map((n) => NotificationCard(notification: n)),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}