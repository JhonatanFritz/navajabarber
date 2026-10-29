const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {defineSecret} = require("firebase-functions/params");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");
const mpWebhookSecret = defineSecret("MP_WEBHOOK_SECRET");
const gmailUser = defineSecret("GMAIL_USER");
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");

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

// Versión original: la usa la demo.
exports.cobrarYape = onCall(
    {secrets: [mpAccessToken]},
    (request) => procesarCobro(request, false),
);

// Versión nueva: ítems, nombre, descriptor y DNI opcional. La usa la copia de Play.
exports.cobrarYapeV2 = onCall(
    {secrets: [mpAccessToken], invoker: "public"},
    (request) => procesarCobro(request, true),
);

// --- NOTIFICACIONES (WEBHOOK) DE MERCADO PAGO ---
// Mercado Pago envía aquí un POST cada vez que cambia una order. La firma del
// header x-signature se valida con HMAC SHA256 sobre el manifiesto
// "id:<data.id en minúsculas>;request-id:<x-request-id>;ts:<ts>;" usando la
// clave secreta del panel. Hay que responder 200 o 201 en menos de 22 segundos.
exports.mpWebhook = onRequest(
    {secrets: [mpWebhookSecret], invoker: "public"},
    (req, res) => {
      if (req.method !== "POST") {
        res.status(405).send("Método no permitido");
        return;
      }

      const xSignature = req.get("x-signature") || "";
      const xRequestId = req.get("x-request-id") || "";
      const dataId = String(req.query["data.id"] || "").toLowerCase();

      let ts = "";
      let v1 = "";
      for (const parte of xSignature.split(",")) {
        const i = parte.indexOf("=");
        if (i === -1) continue;
        const clave = parte.slice(0, i).trim();
        const valor = parte.slice(i + 1).trim();
        if (clave === "ts") ts = valor;
        if (clave === "v1") v1 = valor;
      }
      if (!ts || !v1) {
        res.status(401).send("Firma ausente");
        return;
      }

      // Si falta data.id o x-request-id, se quitan del manifiesto.
      const partes = [];
      if (dataId) partes.push(`id:${dataId}`);
      if (xRequestId) partes.push(`request-id:${xRequestId}`);
      partes.push(`ts:${ts}`);
      const manifiesto = partes.join(";") + ";";

      const esperado = crypto
          .createHmac("sha256", mpWebhookSecret.value())
          .update(manifiesto)
          .digest("hex");

      const a = Buffer.from(esperado);
      const b = Buffer.from(v1);
      if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
        const clave = mpWebhookSecret.value();
        console.warn("Webhook de Mercado Pago con firma inválida", JSON.stringify({
          manifiesto,
          v1Recibido: v1,
          prefijoCalculado: esperado.slice(0, 8),
          largoClave: clave.length,
          claveConEspacios: clave !== clave.trim(),
          encabezados: Object.keys(req.headers),
        }));
        res.status(401).send("Firma inválida");
        return;
      }

      const cuerpo = req.body || {};
      console.log("Webhook de Mercado Pago:", JSON.stringify({
        action: cuerpo.action,
        orderId: cuerpo.data && cuerpo.data.id,
        status: cuerpo.data && cuerpo.data.status,
        statusDetail: cuerpo.data && cuerpo.data.status_detail,
        liveMode: cuerpo.live_mode,
      }));

      res.status(200).send("OK");
    },
);

// --- CORREO DE CONFIRMACIÓN DE RESERVA Y CONSTANCIA DE PAGO ---

function escaparHtml(texto) {
  return String(texto === undefined || texto === null ? "" : texto)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
}

function soles(monto) {
  return `S/ ${Number(monto).toFixed(2)}`;
}

// "2026-10-06" -> "Martes, 6 de octubre de 2026" (hora de Lima).
function formatearFechaLarga(fechaTexto) {
  const fecha = new Date(`${fechaTexto}T12:00:00-05:00`);
  if (isNaN(fecha.getTime())) return String(fechaTexto || "");
  const texto = new Intl.DateTimeFormat("es-PE", {
    timeZone: "America/Lima",
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(fecha);
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

// Fecha ISO -> "06/10/2026 19:55" (hora de Lima).
function formatearFechaHora(iso) {
  const fecha = new Date(iso);
  if (isNaN(fecha.getTime())) return "";
  return new Intl.DateTimeFormat("es-PE", {
    timeZone: "America/Lima",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(fecha);
}

// Consulta la order en Mercado Pago y comprueba que el pago es real, que está
// aprobado, que pertenece al cliente y que el monto es el del depósito.
async function verificarPago(pagoId, clienteId) {
  let resp;
  try {
    resp = await fetch(
        `https://api.mercadopago.com/v1/orders/${encodeURIComponent(pagoId)}`,
        {headers: {Authorization: `Bearer ${mpAccessToken.value()}`}},
    );
  } catch (e) {
    console.warn(`No se pudo consultar la order ${pagoId}:`, e.message);
    return null;
  }
  if (!resp.ok) {
    console.warn(`No se pudo verificar la order ${pagoId}: HTTP ${resp.status}`);
    return null;
  }

  const orden = await resp.json();
  const pago = orden && orden.transactions && orden.transactions.payments &&
    orden.transactions.payments[0];
  const aprobado = orden.status === "processed" && pago && pago.status === "processed";
  const esDelCliente = String(orden.external_reference || "")
      .startsWith(`reserva-${clienteId}-`);
  const pagado = Number(orden.total_paid_amount !== undefined ?
    orden.total_paid_amount : pago && pago.paid_amount);
  const montoOk = pagado === Number(DEPOSITO_RESERVA);

  if (!aprobado || !esDelCliente || !montoOk) {
    console.warn(`Order ${pagoId} no válida para el correo`, JSON.stringify({
      aprobado: Boolean(aprobado),
      esDelCliente,
      montoOk,
    }));
    return null;
  }

  return {
    orderId: orden.id,
    monto: Number(DEPOSITO_RESERVA),
    fechaPago: orden.created_date,
  };
}

// Arma el asunto, el texto y el HTML del correo.
function armarCorreoReserva({nombre, cita, pago, esPrueba}) {
  const precio = Number(cita.servicioPrecio) || 0;
  const saldo = Math.max(0, precio - pago.monto);
  const duracion = cita.servicioDuracion ? ` (${cita.servicioDuracion} min)` : "";

  const asunto =
    `${esPrueba ? "[PRUEBA] " : ""}Reserva confirmada y constancia de pago - La Navaja Maestra`;

  const filasReserva = [
    ["Servicio", cita.servicioNombre],
    ["Barbero", cita.barberoNombre],
    ["Fecha", formatearFechaLarga(cita.fechaTexto)],
    ["Hora", `${cita.hora || ""}${duracion}`],
  ];
  const filasPago = [
    ["Concepto", "Depósito de reserva"],
    ["Monto pagado", soles(pago.monto)],
    ["Medio de pago", "Yape (Mercado Pago)"],
    ["N.º de operación", pago.orderId],
    ["Fecha del pago", formatearFechaHora(pago.fechaPago)],
    ["Estado", "Aprobado"],
    ["Saldo a pagar en el local", soles(saldo)],
  ].filter((f) => f[1]);

  const politica =
    `El depósito de ${soles(pago.monto)} forma parte del precio del servicio ` +
    "y el saldo se paga en el local. Si cancelas la reserva o no asistes, el " +
    "depósito no se devuelve. Si la barbería no puede atenderte, se te devuelve.";
  const aclaracion =
    "Esta constancia confirma el pago del depósito de reserva. " +
    "No es una boleta ni una factura electrónica.";
  const avisoPrueba = "PAGO DE PRUEBA: no se cobró dinero real.";

  const texto = [
    esPrueba ? avisoPrueba : "",
    "¡Reserva confirmada!",
    "",
    `Hola ${nombre}, tu reserva en La Navaja Maestra quedó confirmada y recibimos tu depósito.`,
    "",
    "TU RESERVA",
    ...filasReserva.map((f) => `${f[0]}: ${f[1]}`),
    "",
    "CONSTANCIA DE PAGO DEL DEPÓSITO",
    ...filasPago.map((f) => `${f[0]}: ${f[1]}`),
    "",
    politica,
    "",
    aclaracion,
  ].filter((l, i, arr) => !(l === "" && i === 0)).join("\n");

  const fila = (f) =>
    "<tr>" +
    `<td style="padding:6px 0;color:#666;">${escaparHtml(f[0])}</td>` +
    `<td style="padding:6px 0;text-align:right;font-weight:600;">${escaparHtml(f[1])}</td>` +
    "</tr>";

  const html =
    "<div style=\"font-family:Arial,Helvetica,sans-serif;max-width:520px;margin:0 auto;color:#222;\">" +
    (esPrueba ?
      "<div style=\"background:#FFF4CC;border:1px solid #F0D060;border-radius:8px;" +
      `padding:10px;font-size:13px;margin-bottom:16px;\">${escaparHtml(avisoPrueba)}</div>` :
      "") +
    "<h2 style=\"color:#5B3EF5;margin-bottom:4px;\">¡Reserva confirmada!</h2>" +
    `<p>Hola ${escaparHtml(nombre)}, tu reserva en La Navaja Maestra quedó confirmada y recibimos tu depósito.</p>` +
    "<h3 style=\"margin-bottom:4px;\">Tu reserva</h3>" +
    `<table width="100%" style="border-collapse:collapse;font-size:14px;">${filasReserva.map(fila).join("")}</table>` +
    "<h3 style=\"margin:20px 0 4px;\">Constancia de pago del depósito</h3>" +
    `<table width="100%" style="border-collapse:collapse;font-size:14px;">${filasPago.map(fila).join("")}</table>` +
    `<p style="font-size:13px;color:#555;margin-top:20px;">${escaparHtml(politica)}</p>` +
    `<p style="font-size:12px;color:#888;">${escaparHtml(aclaracion)}</p>` +
    "</div>";

  return {asunto, texto, html};
}

// Se ejecuta cuando la app crea una cita. La región debe coincidir con la de la
// base de datos de Firestore (southamerica-east1).
exports.enviarCorreoReserva = onDocumentCreated(
    {
      document: "citas/{citaId}",
      region: "southamerica-east1",
      secrets: [mpAccessToken, gmailUser, gmailAppPassword],
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const cita = snap.data();
      const ref = snap.ref;

      // Solo reservas con depósito pagado y con los datos necesarios.
      if (cita.depositoPagado !== true || !cita.pagoId || !cita.clienteId) {
        console.log(`Cita ${ref.id} sin depósito pagado: no se envía correo.`);
        return;
      }

      // Evita enviar dos veces (un evento puede entregarse más de una vez).
      const reclamada = await db.runTransaction(async (t) => {
        const actual = await t.get(ref);
        if (actual.get("correoConfirmacion")) return false;
        t.update(ref, {correoConfirmacion: "enviando"});
        return true;
      });
      if (!reclamada) return;

      const marcar = (estado) => ref.update({correoConfirmacion: estado});

      try {
        // Destinatario: el correo de la cuenta del cliente en Firebase Auth.
        const usuario = await admin.auth().getUser(cita.clienteId);
        if (!usuario.email) {
          console.warn(`Cliente ${cita.clienteId} sin correo en su cuenta.`);
          await marcar("sin_correo");
          return;
        }

        // Datos del pago, verificados contra Mercado Pago.
        const esDemo = String(cita.pagoId).startsWith("sim_");
        let pago;
        if (esDemo) {
          if (!MODO_SIMULADO) {
            await marcar("pago_no_verificado");
            return;
          }
          pago = {
            orderId: cita.pagoId,
            monto: Number(DEPOSITO_RESERVA),
            fechaPago: new Date().toISOString(),
          };
        } else {
          pago = await verificarPago(cita.pagoId, cita.clienteId);
          if (!pago) {
            await marcar("pago_no_verificado");
            return;
          }
        }

        const esPrueba = esDemo || PAGOS_DE_PRUEBA;
        const {asunto, texto, html} = armarCorreoReserva({
          nombre: usuario.displayName || "cliente",
          cita,
          pago,
          esPrueba,
        });

        const remitente = gmailUser.value().trim();
        const transporte = nodemailer.createTransport({
          service: "gmail",
          auth: {
            user: remitente,
            pass: gmailAppPassword.value().replace(/\s/g, ""),
          },
        });

        await transporte.sendMail({
          from: `"La Navaja Maestra" <${remitente}>`,
          to: usuario.email,
          subject: asunto,
          text: texto,
          html: html,
        });

        await ref.update({
          correoConfirmacion: "enviado",
          correoEnviadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Correo de reserva enviado (cita ${ref.id}).`);
      } catch (e) {
        console.error(`No se pudo enviar el correo de la cita ${ref.id}:`, e.message);
        await marcar("error");
      }
    },
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