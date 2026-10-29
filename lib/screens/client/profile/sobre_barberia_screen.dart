import 'package:flutter/material.dart';
import '../../../utils/barberia_info.dart';
import 'profile_subpage.dart';

class SobreBarberiaScreen extends StatelessWidget {
  const SobreBarberiaScreen({super.key});

  static const _purple = Color(0xFF5B3EF5);

  void _proximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  Widget _red(BuildContext context, IconData icono, String nombre) {
    return Column(
      children: [
        InkWell(
          onTap: () => _proximamente(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDCD3FB), width: 2),
            ),
            child: Icon(icono, color: _purple),
          ),
        ),
        const SizedBox(height: 4),
        Text(nombre, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpage(
      title: 'Sobre la barbería',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 90,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.content_cut, size: 48, color: _purple),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              BarberiaInfo.nombre,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              BarberiaInfo.actividad,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 24),
          _Fila(
            icono: Icons.place_outlined,
            titulo: 'Dirección',
            valor: BarberiaInfo.direccion,
            onCopiar: () => copiarAlPortapapeles(
              context,
              BarberiaInfo.direccion,
              'Dirección copiada',
            ),
          ),
          _Fila(
            icono: Icons.access_time,
            titulo: 'Horario de atención',
            valor: BarberiaInfo.horario,
          ),
          _Fila(
            icono: Icons.phone_outlined,
            titulo: 'Teléfono y WhatsApp',
            valor: BarberiaInfo.telefono,
            onCopiar: () => copiarAlPortapapeles(
              context,
              BarberiaInfo.telefono,
              'Número copiado',
            ),
          ),
          _Fila(
            icono: Icons.mail_outline,
            titulo: 'Correo',
            valor: BarberiaInfo.correo,
            onCopiar: () => copiarAlPortapapeles(
              context,
              BarberiaInfo.correo,
              'Correo copiado',
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Síguenos en redes',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _red(context, Icons.facebook, 'Facebook'),
              _red(context, Icons.camera_alt_outlined, 'Instagram'),
              _red(context, Icons.music_note, 'TikTok'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final VoidCallback? onCopiar;

  const _Fila({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, size: 22, color: const Color(0xFF5B3EF5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onCopiar != null)
            TextButton(onPressed: onCopiar, child: const Text('Copiar')),
        ],
      ),
    );
  }
}