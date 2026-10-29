import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_subpage.dart';

class DatosPersonalesScreen extends StatefulWidget {
  const DatosPersonalesScreen({super.key});

  @override
  State<DatosPersonalesScreen> createState() => _DatosPersonalesScreenState();
}

class _DatosPersonalesScreenState extends State<DatosPersonalesScreen> {
  final _celularController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final uid = _user?.uid;
    if (uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        final celular = doc.data()?['celular'];
        if (celular is String) _celularController.text = celular;
      } catch (_) {
        // Si no se puede leer, el usuario simplemente verá el campo vacío.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guardar() async {
    final uid = _user?.uid;
    if (uid == null || _saving) return;

    final celular = _celularController.text.trim();
    if (!RegExp(r'^9\d{8}$').hasMatch(celular)) {
      setState(() => _error = 'El celular debe tener 9 dígitos y empezar con 9.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'celular': celular,
        'celularActualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tus datos se guardaron')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return ProfileSubpage(
      title: 'Datos personales',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: user?.displayName ?? '',
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      helperText: 'Vienen de tu cuenta de Google.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _celularController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 9,
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      hintText: '9 dígitos',
                      helperText:
                          'Lo usamos solo para que la barbería pueda comunicarse '
                          'contigo si es necesario, por ejemplo si hay que '
                          'reprogramar tu cita.',
                      helperMaxLines: 3,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No guardamos tu DNI: solo se pide al pagar y se envía a '
                    'Mercado Pago para validar el pago.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5CF0),
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}