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
}