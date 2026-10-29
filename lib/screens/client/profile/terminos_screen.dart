import 'package:flutter/material.dart';
import '../../../utils/barberia_info.dart';
import 'profile_subpage.dart';

class _Seccion {
  final String titulo;
  final String texto;

  const _Seccion(this.titulo, this.texto);
}

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  static const _secciones = <_Seccion>[
    _Seccion(
      '1. Quiénes somos',
      '${BarberiaInfo.nombre} es un negocio de ${BarberiaInfo.titular} '
          '(RUC ${BarberiaInfo.ruc}), con domicilio en ${BarberiaInfo.direccion}. '
          'Esta aplicación permite reservar citas en la barbería y pagar un '
          'anticipo para separar el horario.',
    ),
    _Seccion(
      '2. Uso de la aplicación',
      'Para usar la aplicación inicias sesión con tu cuenta de Google. Debes '
          'dar datos verdaderos y usar la aplicación solo para tus propias '
          'reservas.',
    ),
    _Seccion(
      '3. Reservas y anticipo',
      'Para confirmar una cita se paga un anticipo de S/ 5.00 con Yape, '
          'procesado por Mercado Pago. Ese monto se descuenta del precio final '
          'del servicio. El resto se paga en el local, en efectivo o con Yape.',
    ),
    _Seccion(
      '4. Reprogramación',
      'Puedes reprogramar tu cita una sola vez, hasta 3 horas antes de su hora '
          'de inicio. Tu anticipo se mantiene y pasa a la nueva fecha. Una vez '
          'reprogramada, la cita no se puede reprogramar de nuevo.',
    ),
    _Seccion(
      '5. Cancelación',
      'Puedes cancelar tu cita antes de su hora de inicio. Al cancelar, tu '
          'horario se libera y el anticipo no se devuelve.',
    ),
    _Seccion(
      '6. Tolerancia e inasistencia',
      'Tienes 15 minutos de tolerancia después de la hora de tu cita. Si llegas '
          'más tarde o no asistes, tu horario se libera y el anticipo no se '
          'devuelve.',
    ),
    _Seccion(
      '7. Si la barbería no puede atenderte',
      'Si la barbería cancela o no puede atenderte, te devolvemos el anticipo '
          'o reprogramamos tu cita sin costo, como prefieras.',
    ),
    _Seccion(
      '8. Pagos y comprobante',
      'Los pagos se procesan con Mercado Pago. La aplicación no guarda los '
          'datos de tu cuenta de Yape ni tu DNI: el DNI se envía a Mercado Pago '
          'solo para validar el pago. El correo que recibes al reservar es una '
          'constancia del anticipo y no es una boleta ni una factura. La boleta '
          'de venta se emite en el local.',
    ),
    _Seccion(
      '9. Datos personales',
      'Guardamos tu nombre, correo y celular, tu historial de citas y tus '
          'puntos de Barber Club. Los usamos para gestionar tus reservas, '
          'enviarte recordatorios y comunicarnos contigo si es necesario. No '
          'vendemos tus datos. Puedes pedir que corrijamos o eliminemos tus '
          'datos escribiendo a ${BarberiaInfo.correo}.',
    ),
    _Seccion(
      '10. Notificaciones',
      'Te enviamos recordatorios de tus citas un día antes y una hora antes, '
          'y correos cuando reservas o reprogramas.',
    ),
    _Seccion(
      '11. Cambios en estos términos',
      'Podemos actualizar estos términos. Los cambios se publicarán en esta '
          'pantalla.',
    ),
    _Seccion(
      '12. Contacto',
      'Escríbenos a ${BarberiaInfo.correo} o llámanos al '
          '${BarberiaInfo.telefono}.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileSubpage(
      title: 'Términos y condiciones',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Text(
            'Última actualización: 29 de octubre de 2026',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ..._secciones.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.texto,
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}