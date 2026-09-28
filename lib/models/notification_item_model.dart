enum NotificationType { appointment, points, general }

class NotificationItem {
  final String title;
  final String subtitle;
  final String timeAgo;
  final String groupLabel; // "Hoy", "Ayer", etc.
  final NotificationType type;

  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.groupLabel,
    required this.type,
  });

  // Cuando conectemos Firestore, armamos el objeto desde el documento así:
  factory NotificationItem.fromMap(Map<String, dynamic> data) {
    return NotificationItem(
      title: data['titulo'] ?? '',
      subtitle: data['subtitulo'] ?? '',
      timeAgo: data['tiempoTranscurrido'] ?? '',
      groupLabel: data['grupoFecha'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => NotificationType.general,
      ),
    );
  }
}