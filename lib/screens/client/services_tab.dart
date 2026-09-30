import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import '../../services/service_api.dart';
import '../../widgets/service_card.dart';
import 'service_detail_screen.dart';

class ServicesTab extends StatefulWidget {
  final VoidCallback? onBack;

  const ServicesTab({super.key, this.onBack});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  ServiceCategory _selectedCategory = ServiceCategory.barba;
  late Future<List<Service>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    // TODO: reemplazar por un Stream real desde Firestore (colección 'servicios')
    _servicesFuture = ServiceApi.fetchSampleServices();
  }

  IconData _iconForCategory(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.barba:
        return Icons.face_retouching_natural;
      case ServiceCategory.peinados:
        return Icons.face;
      case ServiceCategory.cortes:
        return Icons.content_cut;
    }
  }

  String _labelForCategory(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.barba:
        return 'Barba';
      case ServiceCategory.peinados:
        return 'Peinados';
      case ServiceCategory.cortes:
        return 'Cortes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Servicios',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ServiceCategory.values.map((category) {
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      width: 76,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                        ),
                      ),
                      child: Icon(
                        _iconForCategory(category),
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              Text(
                _labelForCategory(_selectedCategory),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // --- Lista de servicios, obtenida dinámicamente de la API ---
              Expanded(
                child: FutureBuilder<List<Service>>(
                  future: _servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar servicios: ${snapshot.error}',
                        ),
                      );
                    }

                    final allServices = snapshot.data ?? [];
                    final filtered = allServices
                        .where((s) => s.category == _selectedCategory)
                        .toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay servicios en esta categoría todavía',
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => ServiceCard(
                        service: filtered[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServiceDetailScreen(service: filtered[index]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
