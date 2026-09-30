import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/barber_model.dart';
import '../../../models/service_model.dart';
import 'confirm_booking_screen.dart';

class SelectDateTimeScreen extends StatefulWidget {
  final Service service;
  final Barber? barber; // null significa "Cualquier profesional"

  const SelectDateTimeScreen({super.key, required this.service, this.barber});

  @override
  State<SelectDateTimeScreen> createState() => _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends State<SelectDateTimeScreen> {
  // --- Reglas del negocio ---
  static const _morningStart = TimeOfDay(hour: 9, minute: 0);
  static const _morningEnd = TimeOfDay(hour: 13, minute: 0);
  static const _afternoonStart = TimeOfDay(hour: 14, minute: 0);
  static const _afternoonEnd = TimeOfDay(hour: 18, minute: 0);
  static const _maxDaysAhead = 30;

  static const _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  static const _dayAbbrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  late final DateTime _today;
  late final DateTime _maxDate;
  late DateTime _weekStart; // lunes de la semana visible
  late DateTime _todayWeekStart;
  DateTime? _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _maxDate = _today.add(const Duration(days: _maxDaysAhead));
    _todayWeekStart = _today.subtract(Duration(days: _today.weekday - 1));
    _weekStart = _todayWeekStart;
    _selectedDate =
        _today; // el día actual empieza seleccionado, como en el mockup
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _canGoBack => _weekStart.isAfter(_todayWeekStart);
  bool get _canGoForward =>
      !_weekStart.add(const Duration(days: 7)).isAfter(_maxDate);

  void _goToPreviousWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  void _goToNextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  void _selectDate(DateTime day) {
    setState(() {
      _selectedDate = day;
      _selectedTime = null; // al cambiar de día, se resetea la hora elegida
    });
  }

  List<DateTime> _monthOptions() {
    final months = <DateTime>[];
    var cursor = DateTime(_today.year, _today.month, 1);
    while (!cursor.isAfter(_maxDate)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  void _selectMonth(DateTime monthStart) {
    final targetDay = monthStart.isBefore(_today) ? _today : monthStart;
    setState(
      () => _weekStart = targetDay.subtract(
        Duration(days: targetDay.weekday - 1),
      ),
    );
  }

  // Genera los horarios posibles de un periodo (mañana/tarde), respetando
  // que el servicio completo (inicio + duración) termine dentro del horario.
  List<String> _generateSlots(
    DateTime date,
    TimeOfDay periodStart,
    TimeOfDay periodEnd,
  ) {
    final slots = <String>[];
    var current = DateTime(
      date.year,
      date.month,
      date.day,
      periodStart.hour,
      periodStart.minute,
    );
    final periodEndTime = DateTime(
      date.year,
      date.month,
      date.day,
      periodEnd.hour,
      periodEnd.minute,
    );

    while (!current
        .add(Duration(minutes: widget.service.durationMinutes))
        .isAfter(periodEndTime)) {
      slots.add(
        '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}',
      );
      current = current.add(
        const Duration(minutes: 30),
      ); // los turnos inician cada 30 min
    }
    return slots;
  }

  // TODO: reemplazar por una consulta real a Firestore (citas de ese barbero en esa fecha).
  // Mientras tanto, simulamos horarios ya ocupados de forma determinística (mismo
  // resultado para la misma fecha + barbero, no cambia en cada rebuild).
  List<String> _filterAvailable(List<String> allSlots, DateTime date) {
    final seed = date.day + date.month * 31 + (widget.barber?.id.hashCode ?? 0);
    final random = Random(seed);
    final occupiedCount = min(1 + random.nextInt(3), allSlots.length);
    final shuffled = List<String>.from(allSlots)..shuffle(random);
    final occupied = shuffled.take(occupiedCount).toSet();

    final now = DateTime.now();
    final isToday = _isSameDate(date, _today);

    return allSlots.where((slot) {
      if (occupied.contains(slot)) return false;
      if (isToday) {
        final parts = slot.split(':');
        final slotTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        if (slotTime.isBefore(now)) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildTimeChip(String time) {
    final isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B3EF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B3EF5) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final morningSlots = _selectedDate == null
        ? <String>[]
        : _filterAvailable(
            _generateSlots(_selectedDate!, _morningStart, _morningEnd),
            _selectedDate!,
          );
    final afternoonSlots = _selectedDate == null
        ? <String>[]
        : _filterAvailable(
            _generateSlots(_selectedDate!, _afternoonStart, _afternoonEnd),
            _selectedDate!,
          );

    final canContinue = _selectedDate != null && _selectedTime != null;

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
                  '¿Cuándo quieres venir?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${widget.service.name} - ${widget.service.durationMinutes} min',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              Center(
                child: Text(
                  widget.barber?.name ?? 'Cualquier profesional',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 16),

              // --- Calendario semanal ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        PopupMenuButton<DateTime>(
                          onSelected: _selectMonth,
                          itemBuilder: (context) => _monthOptions()
                              .map(
                                (m) => PopupMenuItem(
                                  value: m,
                                  child: Text(
                                    '${_monthNames[m.month - 1]} ${m.year}',
                                  ),
                                ),
                              )
                              .toList(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _monthNames[_weekStart.month - 1],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_weekStart.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _canGoBack ? _goToPreviousWeek : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: _canGoForward ? _goToNextWeek : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final day = _weekStart.add(Duration(days: i));
                        final isSelectable =
                            !day.isBefore(_today) && !day.isAfter(_maxDate);
                        final isSelected =
                            _selectedDate != null &&
                            _isSameDate(day, _selectedDate!);

                        return GestureDetector(
                          onTap: isSelectable ? () => _selectDate(day) : null,
                          child: Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFDCD3FB)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _dayAbbrev[i],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelectable
                                        ? Colors.black87
                                        : Colors.grey[350],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !isSelectable
                                        ? Colors.grey[350]
                                        : (isSelected
                                              ? const Color(0xFF5B3EF5)
                                              : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Horarios disponibles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (morningSlots.isNotEmpty) ...[
                        Center(
                          child: Text(
                            'Mañana',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: morningSlots.map(_buildTimeChip).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (afternoonSlots.isNotEmpty) ...[
                        Center(
                          child: Text(
                            'Tarde',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: afternoonSlots.map(_buildTimeChip).toList(),
                        ),
                      ],
                      if (morningSlots.isEmpty && afternoonSlots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              'No hay horarios disponibles para este día',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                    ],
                  ),
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
              onPressed: canContinue
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmBookingScreen(
                            service: widget.service,
                            barber: widget.barber,
                            date: _selectedDate!,
                            time: _selectedTime!,
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
