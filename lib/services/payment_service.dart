import 'dart:convert';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Comprobante que devuelve un cobro exitoso.
class PaymentResult {
  final String chargeId;
  final double amount; // en soles
  final bool simulated; // true si no se movió dinero real

  const PaymentResult({
    required this.chargeId,
    required this.amount,
    required this.simulated,
  });
}

class PaymentService {
  // true = pago simulado sin llamar a Mercado Pago (tokens falsos).
  // Debe coincidir con MODO_SIMULADO en functions/index.js.
  static const bool simulado = false;

  // true = se usan credenciales de PRUEBA de Mercado Pago: no se cobra dinero
  // real. Debe coincidir con PAGOS_DE_PRUEBA en functions/index.js.
  static const bool pagosDePrueba = true;

  // Depósito de reserva en soles. Solo sirve para mostrarlo en pantalla:
  // el monto que realmente se cobra lo define el servidor.
  static const double depositoReserva = 5.0;

  // Public Key de PRUEBA de Mercado Pago (Credenciales de prueba).
  // La llave pública no es secreta. NUNCA pongas aquí el Access Token.
  static const String _mpPublicKey = 'APP_USR-91cbcc37-57d7-4f64-ba4b-51189af29895';

  Future<String> createYapeToken({
    required String phoneNumber,
    required String approvalCode,
    required String email,
  }) async {
    if (simulado) {
      await Future.delayed(const Duration(milliseconds: 500));
      // El código 000000 simula un pago rechazado; cualquier otro, uno exitoso.
      return approvalCode == '000000' ? 'sim_rechazado' : 'sim_ok';
    }

    if (_mpPublicKey.startsWith('PEGA_AQUI')) {
      throw Exception('Falta configurar la Public Key de prueba en payment_service.dart');
    }

    // El celular y el código van directo a Mercado Pago; el código nunca pasa
    // por nuestro servidor.
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.https(
              'api.mercadopago.com',
              '/platforms/pci/yape/v1/payment',
              {'public_key': _mpPublicKey},
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phoneNumber': phoneNumber,
              'otp': approvalCode,
              'requestId': _uuidV4(),
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Error de red al crear el token de Yape: $e');
      throw Exception('No se pudo conectar con el servicio de pagos. Revisa tu conexión.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Token de Yape rechazado (${response.statusCode}): ${response.body}');
      throw Exception('El celular o el código de Yape no son correctos, o el código ya no sirve.');
    }

    final data = jsonDecode(response.body);
    final id = data is Map ? data['id'] : null;
    if (id is! String || id.isEmpty) {
      throw Exception('Respuesta inesperada del servicio de pagos.');
    }
    return id;
  }

  Future<PaymentResult> cobrar({
    required String tokenId,
    required String celular,
    required String email,
    required String descripcion,
  }) async {
    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable('cobrarYape')
          .call({
        'tokenId': tokenId,
        'celular': celular,
        'email': email, // el servidor usa el correo de la sesión; esto es informativo
        'descripcion': descripcion,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return PaymentResult(
        chargeId: data['chargeId'] as String,
        amount: (data['monto'] as num) / 100, // el servidor responde en céntimos
        simulated: data['simulado'] == true,
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'No se pudo procesar el cobro');
    }
  }

  // UUID v4 para el requestId del token.
  static String _uuidV4() {
    final random = Random.secure();
    final b = List<int>.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }
}