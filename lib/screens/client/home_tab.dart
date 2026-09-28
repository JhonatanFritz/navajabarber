import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/barber_model.dart';
import '../../models/news_item_model.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/news_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  static const Color _purple = Color(0xFF5B3EF5);
  static const Color _purpleDark = Color(0xFF4A2FD9);

  // TODO: reemplazar por datos reales desde Firestore (colección 'servicios' o 'novedades')
  static const List<NewsItem> _sampleNews = [
    NewsItem(
      title: 'Prueba tu estilo con IA',
      subtitle: 'Descubre tu próximo estilo',
      icon: Icons.auto_awesome,
    ),
    NewsItem(
      title: 'Nuevos asientos',
      subtitle: 'Un corte que te vas a querer',
    ),
  ];

  // TODO: reemplazar por datos reales desde Firestore (colección 'usuarios', rol == 'barbero')
  static const List<Barber> _sampleBarbers = [
    Barber(
      id: '1',
      name: 'Juan José',
      specialty: 'Experto en barbas',
      photoUrl: '',
      rating: 4,
    ),
    Barber(
      id: '2',
      name: 'Roky R.',
      specialty: 'Peinados',
      photoUrl: '',
      rating: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName ?? 'Cliente').split(' ').take(2).join(' ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido\n$firstName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Agenda tu nuevo estilo',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Próxima cita ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_purple, _purpleDark],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.event_available, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '11:11',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                Text('Jueves, 11 de Diciembre',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                                SizedBox(height: 4),
                                Text('Barba Italiana - Carlos J',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: navegar a la pantalla de agendar cita
                            },
                            icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                            label: const Text('Agendar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: navegar a la lista de citas del cliente
                            },
                            icon: const Icon(Icons.event_note_outlined, size: 18),
                            label: const Text('Citas'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Text('Tus puntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF4A2FD9), Color(0xFF17B3A3)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Row(
                                  children: [
                                    Text('BARBER CLUB',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1)),
                                    SizedBox(width: 4),
                                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('25',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                Text('Puntos', style: TextStyle(color: Colors.white, fontSize: 13)),
                                SizedBox(height: 6),
                                Text('75 puntos para tu próxima recompensa',
                                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.star, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text('Novedades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // --- Novedades: se autogenera desde _sampleNews ---
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sampleNews.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => NewsCard(item: _sampleNews[index]),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text('Nuestros profesionales',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // --- Profesionales: se autogenera desde _sampleBarbers ---
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sampleBarbers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => BarberCard(barber: _sampleBarbers[index]),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: navegar a la lista completa de profesionales
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Conoce a nuestros profesionales →'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}