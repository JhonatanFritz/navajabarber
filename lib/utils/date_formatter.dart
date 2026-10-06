class DateFormatter {
  static const List<String> _weekdays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];
  static const List<String> _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static String longDate(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _monthsShort[date.month - 1];
    return '$weekday, ${date.day} $month.';
  }

  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return longDate(date);
  }

  // "2026-10-06": la fecha como texto, sin depender de la zona horaria.
  static String isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}