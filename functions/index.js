const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const crypto = require("crypto");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");

// --- PAGO CON YAPE (MERCADO PAGO) ---

// true = acepta los tokens falsos "sim_ok" / "sim_rechazado" (demostración).
// DEBE pasar a false antes de usar dinero real.
const MODO_SIMULADO = true;

// true mientras se usen credenciales de PRUEBA (no hay dinero real).
const PAGOS_DE_PRUEBA = true;

// Depósito fijo de la reserva (S/ 5.00). Se define aquí, en el servidor.
const DEPOSITO_RESERVA = "5.00";
const DEPOSITO_RESERVA_CENTIMOS = 500;

// Nombre que aparece en el resumen del comprador (máximo 13 caracteres).
const DESCRIPTOR_RESUMEN = "NAVAJAMAESTRA";

const MENSAJES_RECHAZO = {
  insufficient_amount: "Saldo insuficiente en Yape.",
  required_call_for_authorize: "Yape no autorizó el pago. Intenta de nuevo o contacta a Yape.",
  invalid_card_token: "El código de Yape no es válido o venció. Genera uno nuevo.",
  bad_filled_card_data: "El celular o el código de Yape no son correctos.",
  max_attempts_exceeded: "Superaste el máximo de intentos. Intenta más tarde.",
  processing_error: "Hubo un error al procesar el pago. Intenta de nuevo.",
};

// Mercado Pago responde los pagos rechazados con HTTP 402. El motivo viene en
// data.transactions.payments[0].status_detail y también en errors[0].details[0].
function motivoDeRechazo(cuerpo) {
  const pago = cuerpo?.data?.transactions?.payments?.[0];
  if (pago?.status_detail) return pago.status_detail;
  const detalle = cuerpo?.errors?.[0]?.details?.[0];
  if (typeof detalle === "string" && detalle.includes(": ")) {
    return detalle.split(": ").pop();
  }
  return null;
}

// Separa el nombre de la cuenta de Google en nombre y apellido. Es una
// aproximación: con 4 o más palabras toma las dos últimas como apellidos.
function separarNombre(nombreCompleto) {
  const partes = String(nombreCompleto || "")
      .replace(/[^\p{L}\p{M}\s'.-]/gu, " ")
      .trim()
      .split(/\s+/)
      .filter(Boolean);
  let nombre = "";
  let apellido = "";
  if (partes.length === 1) {
    nombre = partes[0];
  } else if (partes.length === 2) {
    nombre = partes[0];
    apellido = partes[1];
  } else if (partes.length === 3) {
    nombre = partes[0];
    apellido = partes.slice(1).join(" ");
  } else if (partes.length >= 4) {
    nombre = partes.slice(0, partes.length - 2).join(" ");
    apellido = partes.slice(-2).join(" ");
  }
  return {nombre: nombre.slice(0, 50), apellido: apellido.slice(0, 50)};
}

// Lógica común del cobro. extendido=false reproduce la order original;
// extendido=true agrega ítems, nombre, descriptor y DNI opcional.
async function procesarCobro(request, extendido) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión para pagar.");
  }

  const {tokenId, celular, dni} = request.data || {};
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

  let dniValido = null;
  if (extendido && dni !== undefined && dni !== null && dni !== "") {
    if (typeof dni !== "string" || !/^\d{8}$/.test(dni)) {
      throw new HttpsError("invalid-argument", "El DNI debe tener 8 dígitos.");
    }
    dniValido = dni;
  }

  const emailPagador = request.auth.token.email;
  if (!emailPagador) {
    throw new HttpsError("failed-precondition", "Tu cuenta no tiene un correo asociado.");
  }

  const orden = {
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
  };

  if (extendido) {
    orden.description = "Depósito de reserva - La Navaja Maestra";
    orden.items = [
      {
        title: "Depósito de reserva",
        unit_price: DEPOSITO_RESERVA,
        quantity: 1,
        description: "Depósito de reserva de cita",
        external_code: "deposito-reserva",
        category_id: "services",
      },
    ];
    const {nombre, apellido} = separarNombre(request.auth.token.name);
    if (nombre) orden.payer.first_name = nombre;
    if (apellido) orden.payer.last_name = apellido;
    if (dniValido) orden.payer.identification = {type: "DNI", number: dniValido};
    orden.transactions.payments[0].payment_method.statement_descriptor =
      DESCRIPTOR_RESUMEN;
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
      body: JSON.stringify(orden),
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

    // Otro error: se registra solo el detalle de los errores (sin datos del pagador).
    console.error(
        "Mercado Pago respondió con error",
        response.status,
        JSON.stringify(data.errors || data.message || "sin detalle"),
    );
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
}

// Versión original: la usa la demo del jueves.
exports.cobrarYape = onCall(
    {secrets: [mpAccessToken]},
    (request) => procesarCobro(request, false),
);

// Versión nueva: ítems, nombre, descriptor y DNI opcional. La usa la copia de Play.
exports.cobrarYapeV2 = onCall(
    {secrets: [mpAccessToken], invoker: "public"},
    (request) => procesarCobro(request, true),
);

// --- HORARIOS OCUPADOS ---
// Devuelve solo hora y duración de las citas confirmadas de un barbero en un día.
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

// Canal de Android con importancia máxima (el mismo que crea la app).
const CANAL_ANDROID = "high_importance_channel";

// El aviso de "hoy tienes una cita" no se envía antes de esta hora (Lima).
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

      // Ventana de "1 hora antes": 45 a 60 minutos (una vez por cita).
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