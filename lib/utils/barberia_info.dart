/// Datos de la barbería. Se usan en "Sobre la barbería", "Ayuda" y
/// "Términos y condiciones". Cuando esté el servidor de Camila, estos valores
/// pueden venir de `GET /barberia`.
class BarberiaInfo {
  static const nombre = 'La Navaja Maestra';
  static const titular = 'Alberto Janampa Torres';
  static const ruc = '10722763381';
  static const direccion = 'Calle Real #257, El Tambo';
  static const telefono = '966860100'; // también es el WhatsApp
  static const correo = 'lanavajam@gmail.com';
  static const horario = '9:00 a 13:00 y de 14:00 a 18:00';
  static const actividad = 'Peluquería y otros tratamientos de belleza';

  // TODO: cuando el negocio tenga sus redes, poner aquí los enlaces y abrirlos
  // con url_launcher.
  static const String? facebookUrl = null;
  static const String? instagramUrl = null;
  static const String? tiktokUrl = null;
}