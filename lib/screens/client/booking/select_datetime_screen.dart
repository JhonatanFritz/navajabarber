import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../models/appointment_model.dart';
import '../../../models/barber_model.dart';
import '../../../models/service_model.dart';
import '../../../services/booking_service.dart';
import '../../../utils/date_formatter.dart';
import 'confirm_booking_screen.dart';

/// Tramo ya ocupado, en minutos desde medianoche: [start, end).
class _BusyRange {
  final int start;
  final int end;

  const _BusyRange(this.start, this.end);
}

class SelectDateTimeScreen extends StatefulWidget {
  final Service? service; // obligatorio al agendar; no se usa al reprogramar
  final Barber? barber; // null significa "Cualquier profesional"

  /// Si viene una cita, la pantalla funciona en modo "Reprogramar":
  /// toma servicio y barbero de la cita y llama a la función `reprogramarCita`.
  final Appointment? reschedule;

  const SelectDateTimeScreen({
    super.key,
    this.service,
    this.barber,
    this.reschedule,
  }) : assert(
          service != null || reschedule != null,
          'Se necesita un servicio o una cita a reprogramar',
        );

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
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _dayAbbrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  late final DateTime _today;
  late final DateTime _maxDate;
  late DateTime _weekStart; // lunes de la semana visible
  late DateTime _todayWeekStart;
  DateTime? _selectedDate;
  String? _selectedTime;

  // Disponibilidad real del barbero en el día elegido
  List<_BusyRange> _busy = [];
  bool _loadingBusy = false;
  String? _busyError;
  int _requestId = 0; // descarta respuestas viejas si se cambia de día rápido

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _maxDate = _today.add(const Duration(days: _maxDaysAhead));
    _todayWeekStart = _today.subtract(Duration(days: _today.weekday - 1));
    _weekStart = _todayWeekStart;
    _selectedDate = _today;

    if (_barberId != null) {
      _loadingBusy = true;
      _fetchBusy(_today);
    }
  }

  bool get _isReschedule => widget.reschedule != null;
  String get _serviceName =>
      widget.reschedule?.servicioNombre ?? widget.service!.name;
  int get _duration =>
      widget.reschedule?.servicioDuracion ?? widget.service!.durationMinutes;
  String? get _barberId =>
      _isReschedule ? widget.reschedule!.barberoId : widget.barber?.id;
  String get _barberName => _isReschedule
      ? widget.reschedule!.barberoNombre
      : (widget.barber?.name ?? 'Cualquier profesional');

  bool _saving = false;

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _loadBusy(DateTime day) {
    // "Cualquier profesional": todavía no se sabe cuántos barberos trabajan
    // cada día, así que no se bloquea ningún horario.
    // TODO: usar los barberos activos cuando existan en Firestore.
    if (_barberId == null) {
      setState(() {
        _busy = [];
        _loadingBusy = false;
        _busyError = null;
      });
      return;
    }

    setState(() {
      _loadingBusy = true;
      _busyError = null;
    });
    _fetchBusy(day);
  }

  Future<void> _fetchBusy(DateTime day) async {
    final requestId = ++_requestId;

    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable('obtenerHorariosOcupados')
          .call({
        'barberoId': _barberId,
        'fechaTexto': DateFormatter.isoDate(day),
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final r = widget.reschedule;
      final isOriginalDay =
          r != null && r.fechaTexto == DateFormatter.isoDate(day);
      final ranges = <_BusyRange>[];
      for (final item in (data['ocupados'] as List)) {
        final m = Map<String, dynamic>.from(item as Map);
        // Al reprogramar, el horario actual de la propia cita no cuenta como ocupado.
        if (isOriginalDay && m['hora'] == r!.hora) continue;
        final start = _toMinutes(m['hora'] as String);
        ranges.add(_BusyRange(start, start + (m['duracion'] as num).toInt()));
      }

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _busy = ranges;
        _loadingBusy = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadingBusy = false;
        _busyError = 'No se pudo cargar la disponibilidad. Intenta de nuevo.';
      });
    }
  }

  Future<void> _confirmReschedule() async {
    if (_saving) return;
    final r = widget.reschedule!;
    setState(() => _saving = true);
    try {
      await BookingService().rescheduleAppointment(
        citaId: r.id,
        fechaTexto: DateFormatter.isoDate(_selectedDate!),
        hora: _selectedTime!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cita fue reprogramada')),
      );
      Navigator.of(context).pop(true); // true = se reprogramó
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'No se pudo reprogramar la cita.')),
      );
      // Si el horario se ocupó mientras elegías, refresca la disponibilidad.
      if (_selectedDate != null) _loadBusy(_selectedDate!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reprogramar la cita.')),
      );
    }
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
    _loadBusy(day);
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

  // Horarios posibles de un periodo; el servicio completo (inicio + duración)
  // debe terminar dentro del periodo.
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
        .add(Duration(minutes: _duration))
        .isAfter(periodEndTime)) {
      slots.add(
        '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}',
      );
      current = current.add(const Duration(minutes: 30));
    }
    return slots;
  }

  // Quita los horarios que se cruzan con una cita del barbero
  // y los que ya pasaron si el día elegido es hoy.
  List<String> _filterAvailable(List<String> allSlots, DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDate(date, _today);
    final duration = _duration;

    return allSlots.where((slot) {
      final start = _toMinutes(slot);
      final end = start + duration;

      for (final busy in _busy) {
        if (start < busy.end && end > busy.start) return false;
      }

      if (isToday) {
        final slotTime = DateTime(
          date.year,
          date.month,
          date.day,
          start ~/ 60,
          start % 60,
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

  Widget _buildSlots() {
    if (_loadingBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_busyError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _busyError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _selectedDate == null
                  ? null
                  : () => _loadBusy(_selectedDate!),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final date = _selectedDate;
    if (date == null) return const SizedBox.shrink();

    final morningSlots = _filterAvailable(
      _generateSlots(date, _morningStart, _morningEnd),
      date,
    );
    final afternoonSlots = _filterAvailable(
      _generateSlots(date, _afternoonStart, _afternoonEnd),
      date,
    );

    return SingleChildScrollView(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final sameAsOriginal = _isReschedule &&
        _selectedDate != null &&
        widget.reschedule!.fechaTexto == DateFormatter.isoDate(_selectedDate!) &&
        widget.reschedule!.hora == _selectedTime;
    final canContinue = _selectedDate != null &&
        _selectedTime != null &&
        !_loadingBusy &&
        !_saving &&
        !sameAsOriginal &&
        _busyError == null;

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
                  Text(
                    _isReschedule ? 'Reprogramar' : 'Agendar',
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
                  '$_serviceName - $_duration min',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              Center(
                child: Text(
                  _barberName,
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
                        final isSelected = _selectedDate != null &&
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

              Expanded(child: _buildSlots()),
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
                  ? (_isReschedule
                      ? _confirmReschedule
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmBookingScreen(
                                service: widget.service!,
                                barber: widget.barber,
                                date: _selectedDate!,
                                time: _selectedTime!,
                              ),
                            ),
                          );
                        })
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
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isReschedule ? 'Confirmar nuevo horario' : 'Continuar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}