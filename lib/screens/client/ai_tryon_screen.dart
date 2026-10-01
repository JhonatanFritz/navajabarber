import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/service_model.dart';
import '../../services/ai_tryon_service.dart';
import '../../services/points_service.dart';
import 'booking/select_barber_screen.dart';

class AiTryOnScreen extends StatefulWidget {
  final Service service;

  const AiTryOnScreen({super.key, required this.service});

  @override
  State<AiTryOnScreen> createState() => _AiTryOnScreenState();
}

class _AiTryOnScreenState extends State<AiTryOnScreen> {
  static const int _cost = 5;
  static const Color _purple = Color(0xFF5B3EF5);

  File? _originalImage;
  Uint8List? _resultBytes;
  bool _isGenerating = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _originalImage = File(picked.path);
      _resultBytes = null;
      _errorMessage = null;
    });

    await _tryGenerate();
  }

  Future<void> _tryGenerate() async {
    if (_originalImage == null) return;

    final currentPoints = await PointsService().getMyPoints();
    if (currentPoints < _cost) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Puntos insuficientes'),
            content: Text(
                'Necesitas al menos $_cost puntos para probar este estilo con IA. Tienes $currentPoints.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final resultBytes = await AiTryOnService().generateStylePreview(
        originalPhoto: _originalImage!,
        serviceName: widget.service.name,
        serviceDescription: widget.service.description,
      );

      await PointsService().spendPointsForAiTryOn(widget.service.name);

      if (mounted) {
        setState(() {
          _resultBytes = resultBytes;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'No se pudo generar la vista previa: $e';
        });
      }
    }
  }

  void _reserveThisService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectBarberScreen(service: widget.service),
      ),
    );
  }

  void _tryAnotherStyle() {
    // Vuelve hasta la raíz (el shell con el menú), donde el cliente
    // sigue viendo la lista de Servicios tal como la dejó.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _resultBytes != null ? _buildResultView() : _buildFormView(),
        ),
      ),
    );
  }

  // --- Estado: resultado generado ---
  Widget _buildResultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 24),
            ),
            const SizedBox(width: 4),
            const Text('Probar con IA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Tu estilo está listo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(_resultBytes!, width: 280, height: 280, fit: BoxFit.cover),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Generado con IA', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(widget.service.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '*Vista previa generada por IA. El resultado es referencial y puede variar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 260,
          child: ElevatedButton(
            onPressed: _reserveThisService,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Text('Reservar este servicio', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _tryAnotherStyle,
          child: const Text('Probar otro estilo', style: TextStyle(color: _purple)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Estado: formulario para elegir/tomar foto ---
  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 24),
            ),
            const SizedBox(width: 4),
            const Text('Probar con IA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Icon(Icons.auto_awesome, size: 20, color: _purple),
            SizedBox(width: 8),
            Text('Pruébate este estilo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              const TextSpan(text: 'Mira cómo podría quedarte la '),
              TextSpan(text: widget.service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' usando una foto tuya.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_originalImage != null)
                  Image.file(_originalImage!, fit: BoxFit.cover)
                else
                  Container(
                    color: Colors.grey[100],
                    child: Icon(Icons.face_retouching_natural, size: 64, color: Colors.grey[400]),
                  ),
                if (_isGenerating)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text('Generando tu estilo...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        const SizedBox(height: 20),
        const Text('¿Cómo funciona?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('1. Toma o selecciona una foto tuya', style: TextStyle(fontSize: 14)),
        const Text('2. La IA aplica el estilo', style: TextStyle(fontSize: 14)),
        const Text('3. Mira cómo podría quedarte', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para mejores resultados: foto frontal · buena iluminación · rostro visible',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isGenerating ? null : () => _pickImage(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Text('Tomar una foto', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isGenerating ? null : () => _pickImage(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: _purple,
              side: const BorderSide(color: _purple),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}