import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Debe ser una función de nivel superior (fuera de cualquier clase).
// Corre en un aislado aparte cuando llega una notificación con la app cerrada
// o en segundo plano. Android ya muestra solo las que traen el bloque
// "notification", así que aquí no hay nada que hacer.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Debe coincidir con el canal que use el servidor y con el meta-data
  // del AndroidManifest.xml.
  static const String channelId = 'high_importance_channel';
  static const String _channelName = 'Notificaciones importantes';
  static const String _channelDescription =
      'Recordatorios de citas, puntos y recompensas';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Canal de importancia máxima: es lo que hace que salga el popup.
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ),
    );

    // Con la app abierta, Android no muestra por su cuenta las notificaciones
    // de FCM: las mostramos nosotros.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Si el token cambia, se vuelve a guardar.
    _messaging.onTokenRefresh.listen(_saveToken);

    // Cada vez que haya una sesión iniciada (también al abrir la app con la
    // sesión ya activa) se guarda el token del celular.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(registerToken());
    });

    // El permiso se pide sin bloquear el arranque de la app.
    unawaited(_requestPermissions());
  }

  Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission();
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notificaciones: error al pedir permiso: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM: no se pudo obtener el token');
        return;
      }
      debugPrint('FCM token: $token');
      await _saveToken(token);
    } catch (e) {
      debugPrint('FCM: error al obtener el token: $e');
    }
  }

  // Guarda el token en el documento del usuario. Reintenta porque, justo
  // después de iniciar sesión por primera vez, el documento puede tardar un
  // momento en existir.
  Future<void> _saveToken(String token) async {
    for (var attempt = 1; attempt <= 5; attempt++) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .update({'fcmToken': token});
        return;
      } catch (e) {
        debugPrint('FCM: no se pudo guardar el token (intento $attempt): $e');
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }
}