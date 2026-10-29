import 'package:flutter/material.dart';
import '../../../utils/barberia_info.dart';
import 'profile_subpage.dart';

class _Pregunta {
  final String pregunta;
  final String respuesta;

  const _Pregunta(this.pregunta, this.respuesta);
}

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  static const _preguntas = <_Pregunta>[
    _Pregunta(
      '¿Cómo reservo una cita?',
      'Entra a "Servicios", elige el servicio y el barbero, escoge la fecha y '
          'la hora, y paga el anticipo de S/ 5.00 con Yape. Al pagar, tu cita '
          'queda confirmada.',
    ),
    _Pregunta(
      '¿Cómo pago con Yape?',
      'Escribe tu número de celular de Yape (el tuyo, no el de la barbería), '
          'tu DNI y el código de aprobación de 6 dígitos que genera tu app '
          'Yape.',
    ),
    _Pregunta(
      '¿Dónde encuentro mi código de aprobación?',
      'Lo genera tu app Yape: busca la opción "Código de aprobación". Son 6 '
          'dígitos y duran poco tiempo; si no funciona, genera uno nuevo.',
    ),
    _Pregunta(
      '¿Cuánto debo pagar en el local?',
      'El anticipo de S/ 5.00 se descuenta del precio del servicio. El resto '
          'lo pagas en el local, en efectivo o con Yape.',
    ),
    _Pregunta(
      '¿Puedo reprogramar mi cita?',
      'Sí, una sola vez y hasta 3 horas antes de la hora de tu cita. Abre la '
          'cita desde "Mis citas" y toca "Reprogramar". Tu anticipo se '
          'mantiene.',
    ),
    _Pregunta(
      '¿Qué pasa si cancelo?',
      'Si cancelas, el anticipo no se devuelve y tu horario se libera.',
    ),
    _Pregunta(
      '¿Qué pasa si llego tarde?',
      'Tienes 15 minutos de tolerancia. Si llegas más tarde, tu horario se '
          'libera y el anticipo no se devuelve.',
    ),
    _Pregunta(
      '¿Y si la barbería no puede atenderme?',
      'Escríbenos o llámanos. Si la barbería no puede atenderte, te '
          'devolvemos el anticipo o reprogramamos tu cita sin costo.',
    ),
    _Pregunta(
      '¿Recibiré recordatorios?',
      'Sí. Te avisamos con una notificación un día antes y una hora antes de '
          'tu cita, y te enviamos un correo cuando reservas o reprogramas.',
    ),
    _Pregunta(
      '¿Cómo funcionan los puntos de Barber Club?',
      'Cada cita atendida suma puntos que puedes canjear por recompensas. '
          'Míralos en "Ver mis puntos".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileSubpage(
      title: 'Ayuda',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          const Text(
            'Preguntas frecuentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._preguntas.map(
            (p) => Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  p.pregunta,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Text(
                    p.respuesta,
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          const Text(
            '¿Necesitas más ayuda?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Escríbenos o llámanos y te ayudamos.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          _ContactoFila(
            icono: Icons.chat_outlined,
            titulo: 'WhatsApp y llamadas',
            valor: BarberiaInfo.telefono,
            copiar: BarberiaInfo.telefono,
            aviso: 'Número copiado',
          ),
          _ContactoFila(
            icono: Icons.mail_outline,
            titulo: 'Correo',
            valor: BarberiaInfo.correo,
            copiar: BarberiaInfo.correo,
            aviso: 'Correo copiado',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ContactoFila extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String copiar;
  final String aviso;

  const _ContactoFila({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.copiar,
    required this.aviso,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          TextButton(
            onPressed: () => copiarAlPortapapeles(context, copiar, aviso),
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }
}