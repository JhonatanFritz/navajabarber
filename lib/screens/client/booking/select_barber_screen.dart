import 'package:flutter/material.dart';

import '../../../models/barber_model.dart';
import '../../../models/service_model.dart';
import '../../../services/barber_api.dart';
import 'select_datetime_screen.dart';

class SelectBarberScreen extends StatefulWidget {
  final Service service;

  const SelectBarberScreen({super.key, required this.service});

  @override
  State<SelectBarberScreen> createState() => _SelectBarberScreenState();
}

class _SelectBarberScreenState extends State<SelectBarberScreen> {
  bool _anyBarber = false;
  Barber? _selectedBarber;
  late Future<List<Barber>> _barbersFuture;

  @override
  void initState() {
    super.initState();
    _barbersFuture = BarberApi.fetchSampleBarbers();
  }

  // "Cualquier profesional" y elegir uno específico son mutuamente excluyentes
  void _toggleAnyBarber(bool value) {
    setState(() {
      _anyBarber = value;
      if (value) _selectedBarber = null;
    });
  }

  void _selectBarber(Barber barber) {
    setState(() {
      _selectedBarber = barber;
      _anyBarber = false;
    });
  }

  bool get _canContinue => _anyBarber || _selectedBarber != null;

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
                  const Text(
                    'Agendar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  '¿Quién quieres que te atienda?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${widget.service.name} - ${widget.service.durationMinutes} min',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Elige un profesional o deja que encontremos uno disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFF17B3A3),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cualquier profesional',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Switch(
                    value: _anyBarber,
                    activeColor: const Color(0xFF5B3EF5),
                    onChanged: _toggleAnyBarber,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                'Nuestros Profesionales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: FutureBuilder<List<Barber>>(
                  future: _barbersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar profesionales: ${snapshot.error}',
                        ),
                      );
                    }

                    final barbers = snapshot.data ?? [];

                    return GridView.builder(
                      itemCount: barbers.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.78,
                          ),
                      itemBuilder: (context, index) {
                        final barber = barbers[index];
                        final isSelected = _selectedBarber?.id == barber.id;

                        return GestureDetector(
                          onTap: () => _selectBarber(barber),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFF5B3EF5),
                                              width: 3,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Image.network(
                                      barber.photoUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                barber.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                barber.specialty,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    barber.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
              onPressed: _canContinue
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectDateTimeScreen(
                            service: widget.service,
                            barber: _selectedBarber, // null si activaron "Cualquier profesional"
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF0),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
