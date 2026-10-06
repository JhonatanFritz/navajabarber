import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification_model.dart';

class NotificationHistoryService {
  // Historial del usuario con sesión iniciada, de la más nueva a la más antigua.
  Stream<List<AppNotification>> streamMyNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const <AppNotification>[]);

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('notificaciones')
        .orderBy('fecha', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}