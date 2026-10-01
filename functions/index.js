const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Envía el push + guarda la notificación en el historial del cliente
async function notificar(clienteId, titulo, cuerpo) {
  await db.collection("usuarios").doc(clienteId)
      .collection("notificaciones").add({
        titulo,
        cuerpo,
        fecha: admin.firestore.FieldValue.serverTimestamp(),
      });

  const usuarioDoc = await db.collection("usuarios").doc(clienteId).get();
  const token = usuarioDoc.data()?.fcmToken;

  if (token) {
    await admin.messaging().send({
      notification: {title: titulo, body: cuerpo},
      token: token,
    });
  }
}

// Lima es UTC-5 todo el año (no tiene horario de verano), así que restamos
// 5 horas antes de comparar el día calendario, sin importar en qué zona
// horaria esté corriendo el servidor de la función.
function diaEnLima(fecha) {
  const limaMs = fecha.getTime() - 5 * 60 * 60 * 1000;
  return new Date(limaMs).toISOString().slice(0, 10); // "YYYY-MM-DD"
}

// Corre sola cada 15 minutos, revisando citas que necesiten recordatorio
exports.enviarRecordatoriosCitas = onSchedule("every 15 minutes", async (event) => {
  const ahora = new Date();

  const citasSnap = await db.collection("citas")
      .where("estado", "==", "confirmada")
      .get();

  for (const doc of citasSnap.docs) {
    const cita = doc.data();

    // Salta cualquier documento con datos incompletos, en vez de romper todo.
    if (!cita.fecha || !cita.hora || !cita.clienteId) {
      console.log(`Cita ${doc.id} con datos incompletos, se omite.`);
      continue;
    }

    const fechaCita = cita.fecha.toDate();

    const [horas, minutos] = cita.hora.split(":").map(Number);
    const fechaHoraCita = new Date(fechaCita);
    fechaHoraCita.setHours(horas, minutos, 0, 0);

    const diffMin = (fechaHoraCita - ahora) / 60000;

    // Recordatorio del día (una vez que amanece el día de la cita)
    const esHoy = diaEnLima(fechaCita) === diaEnLima(ahora);
    if (esHoy && !cita.recordatorioDiaEnviado) {
      await notificar(
          cita.clienteId,
          "¡Hoy tienes una cita!",
          `${cita.servicioNombre} a las ${cita.hora}`,
      );
      await doc.ref.update({recordatorioDiaEnviado: true});
    }

    // Recordatorio de 1 hora antes (ventana de 45-60 min, ya que la función
    // corre cada 15 min, así cada cita cae en esa ventana una sola vez)
    if (diffMin <= 60 && diffMin > 45 && !cita.recordatorio1hEnviado) {
      await notificar(
          cita.clienteId,
          "Tu cita es en 1 hora",
          `${cita.servicioNombre} a las ${cita.hora}`,
      );
      await doc.ref.update({recordatorio1hEnviado: true});
    }
  }
});