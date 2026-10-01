import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/points_transaction_model.dart';
import '../models/reward_model.dart';
import '../models/redemption_model.dart';

class PointsService {
  final _db = FirebaseFirestore.instance;

  Stream<int> streamMyPoints() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _db
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .map((doc) => (doc.data()?['puntos'] ?? 0) as int);
  }

  Stream<List<PointsTransaction>> streamMyTransactions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('transaccionesPuntos')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PointsTransaction.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<int> getMyPoints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await _db.collection('usuarios').doc(uid).get();
    return (doc.data()?['puntos'] ?? 0) as int;
  }

  // Lógica genérica de gasto: valida el saldo y descuenta de forma atómica.
  // La usan tanto la prueba con IA como el canje de recompensas.
  Future<bool> _spendPoints({
    required String description,
    required String subtitle,
    required int cost,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final usuarioRef = _db.collection('usuarios').doc(uid);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(usuarioRef);
      final current = (snapshot.data()?['puntos'] ?? 0) as int;
      if (current < cost) return false;

      transaction.update(usuarioRef, {'puntos': FieldValue.increment(-cost)});
      final transRef = usuarioRef.collection('transaccionesPuntos').doc();
      transaction.set(transRef, {
        'descripcion': description,
        'subtitulo': subtitle,
        'puntos': -cost,
        'fecha': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<bool> spendPointsForAiTryOn(String serviceName) {
    return _spendPoints(
      description: serviceName,
      subtitle: 'Prueba con IA',
      cost: 5,
    );
  }

  Future<bool> redeemReward(Reward reward) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final usuarioRef = _db.collection('usuarios').doc(uid);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(usuarioRef);
      final current = (snapshot.data()?['puntos'] ?? 0) as int;
      if (current < reward.cost) return false;

      // 1. Descuenta los puntos
      transaction.update(usuarioRef, {
        'puntos': FieldValue.increment(-reward.cost),
      });

      // 2. Registra el movimiento en el historial de puntos
      final transRef = usuarioRef.collection('transaccionesPuntos').doc();
      transaction.set(transRef, {
        'descripcion': reward.name,
        'subtitulo': 'Recompensa canjeada',
        'puntos': -reward.cost,
        'fecha': FieldValue.serverTimestamp(),
      });

      // 3. Crea el "voucher" del canje, pendiente de usarse en el local
      final canjeRef = _db.collection('canjes').doc();
      transaction.set(canjeRef, {
        'clienteId': uid,
        'recompensaNombre': reward.name,
        'recompensaDescripcion': reward.description,
        'costoPuntos': reward.cost,
        'estado': 'pendiente',
        'fechaCanje': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  // Trae los canjes del cliente actual
  Stream<List<Redemption>> streamMyRedemptions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _db
        .collection('canjes')
        .where('clienteId', isEqualTo: uid)
        .orderBy('fechaCanje', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Redemption.fromMap(d.id, d.data())).toList(),
        );
  }
}
