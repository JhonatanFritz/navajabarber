import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/payment_service.dart';

class YapePaymentScreen extends StatefulWidget {
  final String email;
  final String description;

  const YapePaymentScreen({
    super.key,
    required this.email,
    required this.description,
  });

  @override
  State<YapePaymentScreen> createState() => _YapePaymentScreenState();
}

class _YapePaymentScreenState extends State<YapePaymentScreen> {
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  String get _modeNotice {
    if (PaymentService.simulado) {
      return 'Modo demostración: no se cobrará dinero real. '
          'Usa cualquier código de 6 dígitos (000000 simula un pago rechazado) '
          'y cualquier DNI de 8 dígitos.';
    }
    if (PaymentService.pagosDePrueba) {
      return 'Modo de pruebas: no se cobrará dinero real. '
          'Usa el celular 111111111, el código 123456 y cualquier DNI de 8 dígitos.';
    }
    return '';
  }

  Future<void> _pagar() async {
    final phone = _phoneController.text.trim();
    final dni = _dniController.text.trim();
    final code = _codeController.text.trim();

    if (phone.length != 9 || code.length != 6) {
      setState(() => _errorMessage = 'Ingresa un celular de 9 dígitos y un código de 6 dígitos');
      return;
    }
    if (dni.isEmpty ? PaymentService.dniObligatorio : dni.length != 8) {
      setState(() => _errorMessage = 'Ingresa tu DNI de 8 dígitos');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = PaymentService();

      final tokenId = await service.createYapeToken(
        phoneNumber: phone,
        approvalCode: code,
        email: widget.email,
      );

      final result = await service.cobrar(
        tokenId: tokenId,
        celular: phone,
        email: widget.email,
        descripcion: widget.description,
        dni: dni,
      );

      if (!mounted) return;
      Navigator.pop(context, result); // devuelve el comprobante del pago
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dniController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amount = PaymentService.depositoReserva;
    final notice = _modeNotice;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Pagar con Yape',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              if (notice.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Text(notice, style: const TextStyle(fontSize: 12)),
                ),

              const Text('Depósito de reserva',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('S/ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 9,
                decoration: const InputDecoration(
                  labelText: 'Celular asociado a Yape',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dniController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: PaymentService.dniObligatorio ? 'DNI' : 'DNI (opcional)',
                  helperText:
                      'Se envía a Mercado Pago solo para validar el pago. No lo guardamos.',
                  helperMaxLines: 2,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código de aprobación',
                  helperText:
                      'Es el código de 6 dígitos que genera tu app Yape. '
                      'Si no funciona, genera uno nuevo.',
                  helperMaxLines: 2,
                  counterText: '',
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'Si no asistes a tu cita o la cancelas, los '
                  'S/ ${amount.toStringAsFixed(2)} del depósito no serán devueltos.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _pagar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5CF0),
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Pagar S/ ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}