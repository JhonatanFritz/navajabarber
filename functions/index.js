const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const crypto = require("crypto");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");

// --- PAGO CON YAPE (MERCADO PAGO) ---

// true = acepta los tokens falsos "sim_ok" / "sim_rechazado" (demostración
// sin llamar a Mercado Pago). DEBE pasar a false antes de usar dinero real.
const MODO_SIMULADO = true;

// true mientras se usen credenciales de PRUEBA de Mercado Pago (no hay dinero
// real). Pasar a false solo cuando se instalen credenciales de producción.
const PAGOS_DE_PRUEBA = true;

// Depósito fijo de la reserva (S/ 5.00). Se define aquí, en el servidor.
const DEPOSITO_RESERVA = "5.00";
const DEPOSITO_RESERVA_CENTIMOS = 500;

const MENSAJES_RECHAZO = {
  insufficient_amount: "Saldo insuficiente en Yape.",
  required_call_for_authorize: "Yape no autorizó el pago. Intenta de nuevo o contacta a Yape.",
  invalid_card_token: "El código de Yape no es válido o venció. Genera uno nuevo.",
  bad_filled_card_data: "El celular o el código de Yape no son correctos.",
  max_attempts_exceeded: "Superaste el máximo de intentos. Intenta más tarde.",
  processing_error: "Hubo un error al procesar el pago. Intenta de nuevo.",
};

// Mercado Pago responde los pagos rechazados con HTTP 402. El motivo viene en
// data.transactions.payments[0].status_detail y también en errors[0].details[0],
// con la forma "ID_DEL_PAGO: motivo".
function motivoDeRechazo(cuerpo) {
  const pago = cuerpo?.data?.transactions?.payments?.[0];
  if (pago?.status_detail) return pago.status_detail;
  const detalle = cuerpo?.errors?.[0]?.details?.[0];
  if (typeof detalle === "string" && detalle.includes(": ")) {
    return detalle.split(": ").pop();
  }
  return null;
}

exports.cobrarYape = onCall({secrets: [mpAccessToken]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión para pagar.");
  }

  const {tokenId, celular} = request.data;
  if (!tokenId || typeof tokenId !== "string") {
    throw new HttpsError("invalid-argument", "Falta el token de pago.");
  }

  // Modo demostración: no se llama a Mercado Pago.
  if (MODO_SIMULADO && tokenId.startsWith("sim_")) {
    await new Promise((resolve) => setTimeout(resolve, 1500));

    if (tokenId === "sim_rechazado") {
      throw new HttpsError("failed-precondition", "Pago rechazado (simulación).");
    }
    if (tokenId !== "sim_ok") {
      throw new HttpsError("invalid-argument", "Token de simulación no válido.");
    }

    return {
      success: true,
      simulado: true,
      monto: DEPOSITO_RESERVA_CENTIMOS,
      chargeId: `sim_${Date.now()}`,
    };
  }

  // Pago con Mercado Pago.
  if (typeof celular !== "string" || !/^\d{9}$/.test(celular)) {
    throw new HttpsError("invalid-argument", "El celular de Yape no es válido.");
  }

  const emailPagador = request.auth.token.email;
  if (!emailPagador) {
    throw new HttpsError("failed-precondition", "Tu cuenta no tiene un correo asociado.");
  }

  let response;
  try {
    response = await fetch("https://api.mercadopago.com/v1/orders", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${mpAccessToken.value()}`,
        "Content-Type": "application/json",
        "X-Idempotency-Key": crypto.randomUUID(),
      },
      body: JSON.stringify({
        type: "online",
        external_reference: `reserva-${request.auth.uid}-${Date.now()}`,
        processing_mode: "automatic",
        total_amount: DEPOSITO_RESERVA,
        payer: {
          email: emailPagador,
          entity_type: "individual",
          phone: {area_code: "51", number: celular},
        },
        transactions: {
          payments: [
            {
              amount: DEPOSITO_RESERVA,
              payment_method: {id: "yape", type: "debit_card", token: tokenId},
            },
          ],
        },
      }),
    });
  } catch (e) {
    console.error("No se pudo contactar a Mercado Pago", e);
    throw new HttpsError("unavailable", "No se pudo contactar al servicio de pagos. Intenta de nuevo.");
  }

  let data = {};
  try {
    data = await response.json();
  } catch (e) {
    data = {};
  }

  if (!response.ok) {
    const motivo = motivoDeRechazo(data);

    // Pago rechazado por Yape / Mercado Pago: se le explica el motivo al cliente.
    if (response.status === 402 && motivo) {
      console.log("Pago rechazado por Mercado Pago:", motivo);
      throw new HttpsError(
          "failed-precondition",
          MENSAJES_RECHAZO[motivo] || "El pago fue rechazado.",
      );
    }

    // Cualquier otro error: se guarda el detalle completo para depurar.
    console.error("Mercado Pago respondió con error", response.status, JSON.stringify(data));
    throw new HttpsError("failed-precondition", "No se pudo procesar el pago. Intenta de nuevo.");
  }

  const pago = data.transactions && data.transactions.payments && data.transactions.payments[0];
  const aprobado = data.status === "processed" && pago && pago.status === "processed";

  if (!aprobado) {
    const detalle = (pago && pago.status_detail) || data.status_detail;
    console.error("Pago no aprobado", data.status, detalle);
    throw new HttpsError(
        "failed-precondition",
        MENSAJES_RECHAZO[detalle] || "El pago fue rechazado.",
    );
  }

  return {
    success: true,
    simulado: PAGOS_DE_PRUEBA,
    monto: DEPOSITO_RESERVA_CENTIMOS,
    chargeId: data.id,
  };
});

// --- HORARIOS OCUPADOS ---
// Devuelve solo hora y duración de las citas confirmadas de un barbero en un día.
// No expone ningún dato de otros clientes.
exports.obtenerHorariosOcupados = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const {barberoId, fechaTexto} = request.data;
  if (
    !barberoId || typeof barberoId !== "string" ||
    typeof fechaTexto !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(fechaTexto)
  ) {
    throw new HttpsError("invalid-argument", "Faltan datos o tienen formato incorrecto.");
  }

  const snap = await db.collection("citas")
      .where("barberoId", "==", barberoId)
      .where("fechaTexto", "==", fechaTexto)
      .where("estado", "==", "confirmada")
      .get();

  return {
    ocupados: snap.docs.map((d) => ({
      hora: d.data().hora,
      duracion: d.data().servicioDuracion,
    })),
  };
});

// --- RECORDATORIOS ---

// Canal de Android con importancia máxima (el mismo que crea la app en
// NotificationService). Sin él, el push no sale como popup.
const CANAL_ANDROID = "high_importance_channel";

// El aviso de "hoy tienes una cita" no se envía antes de esta hora (Lima),
// para no avisar de madrugada.
const HORA_MINIMA_AVISO_DIA = 7;

// Lima es UTC-5 todo el año (no tiene horario de verano).
const LIMA_OFFSET_MS = 5 * 60 * 60 * 1000;

function diaEnLima(fecha) {
  return new Date(fecha.getTime() - LIMA_OFFSET_MS).toISOString().slice(0, 10);
}

function horaEnLima(fecha) {
  return new Date(fecha.getTime() - LIMA_OFFSET_MS).getUTCHours();
}

// Guarda la notificación en el historial del cliente y envía el push.
async function notificar(clienteId, titulo, cuerpo) {
  const usuarioRef = db.collection("usuarios").doc(clienteId);

  await usuarioRef.collection("notificaciones").add({
    titulo,
    cuerpo,
    fecha: admin.firestore.FieldValue.serverTimestamp(),
  });

  const usuarioDoc = await usuarioRef.get();
  const token = usuarioDoc.data()?.fcmToken;

  if (!token) {
    console.log(`Usuario ${clienteId} sin fcmToken: solo se guardó la notificación.`);
    return;
  }

  try {
    await admin.messaging().send({
      token: token,
      notification: {title: titulo, body: cuerpo},
      android: {
        priority: "high",
        notification: {channelId: CANAL_ANDROID},
      },
    });
  } catch (e) {
    console.error(`No se pudo enviar el push a ${clienteId}:`, e.code || e.message);
    // Si el token ya no sirve, se borra para no seguir intentándolo.
    if (
      e.code === "messaging/registration-token-not-registered" ||
      e.code === "messaging/invalid-registration-token"
    ) {
      await usuarioRef.update({fcmToken: admin.firestore.FieldValue.delete()});
    }
  }
}

exports.enviarRecordatoriosCitas = onSchedule("every 15 minutes", async (event) => {
  const ahora = new Date();
  const hoyLima = diaEnLima(ahora);
  const horaActualLima = horaEnLima(ahora);

  const citasSnap = await db.collection("citas")
      .where("estado", "==", "confirmada")
      .get();

  for (const doc of citasSnap.docs) {
    try {
      const cita = doc.data();

      // Las citas antiguas (sin fechaTexto) o incompletas se omiten.
      if (!cita.fechaTexto || !cita.hora || !cita.clienteId) {
        console.log(`Cita ${doc.id} con datos incompletos, se omite.`);
        continue;
      }

      // La hora de la cita se interpreta siempre en horario de Lima (-05:00).
      const fechaHoraCita = new Date(`${cita.fechaTexto}T${cita.hora}:00-05:00`);
      if (isNaN(fechaHoraCita.getTime())) {
        console.log(`Cita ${doc.id} con fecha u hora inválida, se omite.`);
        continue;
      }
      const diffMin = (fechaHoraCita - ahora) / 60000;

      // Ventana de "1 hora antes": 45 a 60 minutos. Como la función corre cada
      // 15 minutos, cada cita cae en esta ventana una sola vez.
      const avisarUnaHora =
        diffMin <= 60 && diffMin > 45 && !cita.recordatorio1hEnviado;

      // Aviso del día: solo el mismo día, desde las 07:00 y antes de la cita.
      const avisarHoy =
        cita.fechaTexto === hoyLima &&
        diffMin > 0 &&
        horaActualLima >= HORA_MINIMA_AVISO_DIA &&
        !cita.recordatorioDiaEnviado;

      if (avisarUnaHora) {
        await notificar(
            cita.clienteId,
            "Tu cita es en 1 hora",
            `${cita.servicioNombre} a las ${cita.hora}`,
        );
        // Si ya avisamos de la hora, el aviso del día queda sin efecto.
        await doc.ref.update({
          recordatorio1hEnviado: true,
          recordatorioDiaEnviado: true,
        });
      } else if (avisarHoy) {
        await notificar(
            cita.clienteId,
            "¡Hoy tienes una cita!",
            `${cita.servicioNombre} a las ${cita.hora}`,
        );
        await doc.ref.update({recordatorioDiaEnviado: true});
      }
    } catch (e) {
      console.error(`Error procesando la cita ${doc.id}:`, e);
    }
  }
});