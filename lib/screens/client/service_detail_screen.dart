import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import 'ai_tryon_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Service service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final images = service.images.isNotEmpty
        ? service.images
        : [service.imageUrl];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Detalles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // --- Carrusel de imágenes con efecto de "peek" en los laterales ---
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final page =
                            _pageController.page ?? _currentPage.toDouble();
                        scale = (1 - (page - index).abs() * 0.25).clamp(
                          0.8,
                          1.0,
                        );
                      }
                      return Center(
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Indicador de puntos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 8 : 6,
                  height: isActive ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.black87 : Colors.grey[350],
                  ),
                );
              }),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'S/ ${service.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${service.durationMinutes} min',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Pruébalo antes de reservar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mira cómo podría quedarte este estilo usando una foto tuya',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Probar con IA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AiTryOnScreen(service: service),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF17B3A3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFF17B3A3),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '5 puntos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vista previa generada por IA. El resultado es referencial.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[500],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      '¿Qué incluye?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.includes.join(' · '),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: navegar al flujo de reserva del servicio
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Reservar servicio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
