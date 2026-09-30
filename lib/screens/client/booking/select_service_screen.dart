import 'package:flutter/material.dart';
import '../../../models/service_model.dart';
import '../../../services/service_api.dart';
import '../../../widgets/service_card.dart';
import 'select_barber_screen.dart';

class SelectServiceScreen extends StatefulWidget {
  const SelectServiceScreen({super.key});

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {
  ServiceCategory _selectedCategory = ServiceCategory.barba;
  String _searchQuery = '';
  Service? _selectedService;
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 4),
                  const Text('Agendar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('¿Qué servicio quieres agendar?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Elige el servicio que deseas realizarte',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 16),

              // --- Chips de categoría ---
              Row(
                children: ServiceCategory.values.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconForCategory(category),
                                size: 16, color: isSelected ? Colors.white : Colors.black87),
                            const SizedBox(width: 6),
                            Text(
                              _labelForCategory(category),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // --- Buscador ---
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5B3EF5), width: 1.5),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar servicio...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B3EF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.search, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Lista filtrada ---
              Expanded(
                child: FutureBuilder<List<Service>>(
                  future: _servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error al cargar servicios: ${snapshot.error}'));
                    }

                    final allServices = snapshot.data ?? [];
                    final filtered = allServices.where((s) {
                      final matchesCategory = s.category == _selectedCategory;
                      final matchesSearch = _searchQuery.isEmpty ||
                          s.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      return matchesCategory && matchesSearch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No se encontraron servicios'));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final service = filtered[index];
                        return ServiceCard(
                          service: service,
                          showDetailsLink: false,
                          selected: _selectedService?.id == service.id,
                          onTap: () => setState(() => _selectedService = service),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedService == null
                  ? null
                  : () {
                      // TODO: navegar al siguiente paso (elegir barbero, fecha y hora)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectBarberScreen(service: _selectedService!),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF0),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}