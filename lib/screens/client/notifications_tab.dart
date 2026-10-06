import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/notification_item_model.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/notification_card.dart';

class NotificationsTab extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationsTab({super.key, this.onBack});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();

    // Historial del usuario con sesión iniciada, de la más nueva a la más antigua.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _stream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('notificaciones')
          .orderBy('fecha', descending: true)
          .limit(100)
          .snapshots();
    }

    // Refresca cada minuto los textos "Hace 5 min", "Hace 1 hora", etc.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // --- Conversión de un documento de Firestore a NotificationItem ---

  NotificationItem _toItem(Map<String, dynamic> data) {
    final raw = data['fecha'];
    final fecha = raw is Timestamp ? raw.toDate() : DateTime.now();
    final title = (data['titulo'] ?? '').toString();

    return NotificationItem(
      title: title,
      subtitle: (data['cuerpo'] ?? '').toString(),
      timeAgo: _timeAgo(fecha),
      groupLabel: _groupLabel(fecha),
      type: _typeFor(title),
    );
  }

  // Por ahora el tipo se deduce del título. Más adelante conviene que el
  // servidor guarde un campo "tipo" y leerlo aquí.
  NotificationType _typeFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('punto')) return NotificationType.points;
    if (t.contains('cita')) return NotificationType.appointment;
    return NotificationType.general;
  }

  String _timeAgo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Justo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? 'Hace 1 hora' : 'Hace $h horas';
    }
    final d = diff.inDays;
    return d == 1 ? 'Hace 1 día' : 'Hace $d días';
  }

  String _groupLabel(DateTime fecha) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final dias = hoy.difference(dia).inDays;

    if (dias <= 0) return 'Hoy';
    if (dias == 1) return 'Ayer';
    return DateFormatter.longDate(fecha);
  }

  // Agrupa la lista en secciones por groupLabel, manteniendo el orden original
  Map<String, List<NotificationItem>> _groupByDate(List<NotificationItem> items) {
    final Map<String, List<NotificationItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.groupLabel, () => []).add(item);
    }
    return grouped;
  }

  Widget _centeredMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildList() {
    final stream = _stream;
    if (stream == null) {
      return _centeredMessage('Inicia sesión para ver tus notificaciones');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Notificaciones: error al leer el historial: ${snapshot.error}');
          return _centeredMessage('No se pudieron cargar tus notificaciones.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs.map((d) => _toItem(d.data())).toList();
        if (items.isEmpty) {
          return _centeredMessage('No tienes notificaciones todavía');
        }

        final grouped = _groupByDate(items);

        return ListView(
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
        );
      },
    );
  }

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
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
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

              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }
}