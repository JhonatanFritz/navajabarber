import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/points_transaction_model.dart';

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

  // Descuenta puntos para usar la prueba con IA. Usa una transacción para evitar
  // que, con doble clic o mala conexión, alguien gaste más de lo que tiene.
  Future<bool> spendPointsForAiTryOn(String serviceName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    const cost = 5;
    final usuarioRef = _db.collection('usuarios').doc(uid);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(usuarioRef);
      final current = (snapshot.data()?['puntos'] ?? 0) as int;
      if (current < cost) return false;

      transaction.update(usuarioRef, {'puntos': FieldValue.increment(-cost)});
      final transRef = usuarioRef.collection('transaccionesPuntos').doc();
      transaction.set(transRef, {
        'descripcion': serviceName,
        'subtitulo': 'Prueba con IA',
        'puntos': -cost,
        'fecha': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}
