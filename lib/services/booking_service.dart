import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';

class BookingService {
  final _db = FirebaseFirestore.instance;

  Future<String> createAppointment(Appointment appointment) async {
    final docRef = await _db.collection('citas').add(appointment.toMap());
    return docRef.id;
  }

  Future<void> cancelAppointment(String id) async {
    await _db.collection('citas').doc(id).update({'estado': 'cancelada'});
  }

  /// Reprograma la cita (una sola vez, hasta 3 horas antes).
  /// Las reglas las valida la Cloud Function `reprogramarCita`.
  /// Lanza [FirebaseFunctionsException] con el motivo si no se puede.
  Future<void> rescheduleAppointment({
    required String citaId,
    required String fechaTexto, // "2026-10-30"
    required String hora, // "15:30"
  }) async {
    await FirebaseFunctions.instance.httpsCallable('reprogramarCita').call({
      'citaId': citaId,
      'fechaTexto': fechaTexto,
      'hora': hora,
    });
  }

  // El barbero llama a esto desde su agenda cuando el cliente asiste y paga.
  // Marca la cita como atendida Y otorga los puntos, todo en una sola operación atómica.
  Future<void> markAsAttended({
    required String citaId,
    required String clienteId,
    required String servicioNombre,
    required double servicioPrecio,
  }) async {
    final points = (servicioPrecio * 0.5).round(); // 50% del precio, regla acordada mientras se define con administración

    final batch = _db.batch();

    final citaRef = _db.collection('citas').doc(citaId);
    batch.update(citaRef, {'estado': 'atendida'});

    final usuarioRef = _db.collection('usuarios').doc(clienteId);
    batch.update(usuarioRef, {'puntos': FieldValue.increment(points)});

    final transRef = usuarioRef.collection('transaccionesPuntos').doc();
    batch.set(transRef, {
      'descripcion': servicioNombre,
      'subtitulo': 'Cita completada',
      'puntos': points,
      'fecha': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Trae TODAS las citas del cliente; la separación en Próximas/Historial
  // se hace en la pantalla, según fecha Y estado a la vez.
  Stream<List<Appointment>> streamMyAppointments() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return _db
        .collection('citas')
        .where('clienteId', isEqualTo: uid)
        .orderBy('fecha')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromMap(d.id, d.data())).toList());
  }
}