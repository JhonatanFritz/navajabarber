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

  /// Crea la cita a través de la función `crearCita`, que verifica en el
  /// servidor que el anticipo esté pagado, que el pago no se haya usado antes
  /// y que el horario siga libre. Devuelve el id de la cita.
  /// Lanza [FirebaseFunctionsException] con un mensaje listo para mostrar.
  Future<String> createPaidAppointment(Appointment a) async {
    final response =
        await FirebaseFunctions.instance.httpsCallable('crearCita').call({
      'pagoId': a.pagoId,
      'servicioNombre': a.servicioNombre,
      'servicioPrecio': a.servicioPrecio,
      'servicioDuracion': a.servicioDuracion,
      'barberoId': a.barberoId,
      'barberoNombre': a.barberoNombre,
      'barberoEspecialidad': a.barberoEspecialidad,
      'fechaTexto': a.fechaTexto,
      'hora': a.hora,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['citaId'] as String;
  }

  /// Pregunta al servidor si el horario sigue libre para ese barbero.
  /// Con "Cualquier profesional" (sin barbero) no hay nada que comprobar.
  /// Si no se puede consultar, devuelve true: la verificación definitiva
  /// la hace `crearCita` al confirmar.
  Future<bool> slotLibre({
    required String? barberoId,
    required String fechaTexto,
    required String hora,
    required int duracion,
  }) async {
    if (barberoId == null) return true;
    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable('obtenerHorariosOcupados')
          .call({'barberoId': barberoId, 'fechaTexto': fechaTexto});
      final data = Map<String, dynamic>.from(response.data as Map);
      final inicio = _minutos(hora);
      final fin = inicio + duracion;
      for (final item in (data['ocupados'] as List)) {
        final m = Map<String, dynamic>.from(item as Map);
        final otroInicio = _minutos(m['hora'] as String);
        final otroFin = otroInicio + (m['duracion'] as num).toInt();
        if (inicio < otroFin && fin > otroInicio) return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  int _minutos(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
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