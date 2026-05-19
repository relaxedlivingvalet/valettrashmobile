/// Shared clock-in/out parsing and hour totals for worker, OM, and owner views.
abstract final class ClockHours {
  static String formatDuration(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h <= 0 && m <= 0) return '0h';
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static String formatMoney(double amount) =>
      '\$${amount.toStringAsFixed(2)}';

  static String formatTimestamp(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  static String formatTimestampShort(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// Latest event for [userId] (any property) is clock_in.
  static bool isClockedIn(
    List<Map<String, dynamic>> events, {
    String? userId,
  }) {
    final filtered = userId == null
        ? events
        : events.where((e) => e['user_id']?.toString() == userId).toList();
    if (filtered.isEmpty) return false;
    filtered.sort((a, b) {
      final ta = DateTime.parse(a['created_at'] as String);
      final tb = DateTime.parse(b['created_at'] as String);
      return ta.compareTo(tb);
    });
    return filtered.last['event_type']?.toString() == 'clock_in';
  }

  /// Pair clock_in with the next clock_out (events sorted ascending).
  static List<ClockShift> shiftsFromEvents(List<Map<String, dynamic>> events) {
    final sorted = List<Map<String, dynamic>>.from(events)
      ..sort((a, b) {
        final ta = DateTime.parse(a['created_at'] as String);
        final tb = DateTime.parse(b['created_at'] as String);
        return ta.compareTo(tb);
      });

    final shifts = <ClockShift>[];
    DateTime? lastIn;
    String? inIso;
    String? propertyId;

    for (final e in sorted) {
      final type = e['event_type']?.toString();
      final iso = e['created_at'] as String;
      final ts = DateTime.parse(iso).toLocal();
      if (type == 'clock_in') {
        lastIn = ts;
        inIso = iso;
        propertyId = e['property_id']?.toString();
      } else if (type == 'clock_out' && lastIn != null) {
        shifts.add(ClockShift(
          clockIn: lastIn,
          clockInIso: inIso!,
          clockOut: DateTime.parse(iso).toLocal(),
          clockOutIso: iso,
          propertyId: propertyId,
        ));
        lastIn = null;
        inIso = null;
        propertyId = null;
      }
    }

    if (lastIn != null && inIso != null) {
      shifts.add(ClockShift(
        clockIn: lastIn,
        clockInIso: inIso,
        propertyId: propertyId,
        open: true,
      ));
    }
    return shifts;
  }

  static double totalHours(
    List<ClockShift> shifts, {
    required DateTime since,
  }) {
    var total = 0.0;
    for (final s in shifts) {
      if (s.clockIn.isBefore(since) && (s.clockOut == null || s.clockOut!.isBefore(since))) {
        continue;
      }
      total += s.hoursSince(since);
    }
    return total;
  }

  static double laborCost({
    required double hours,
    required double hourlyRate,
  }) =>
      hours * hourlyRate;

  static DateTime weekStartLocal([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  static DateTime monthStartLocal([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
}

class ClockShift {
  const ClockShift({
    required this.clockIn,
    required this.clockInIso,
    this.clockOut,
    this.clockOutIso,
    this.propertyId,
    this.open = false,
  });

  final DateTime clockIn;
  final String clockInIso;
  final DateTime? clockOut;
  final String? clockOutIso;
  final String? propertyId;
  final bool open;

  double get hours {
    final end = clockOut ?? DateTime.now();
    return end.difference(clockIn).inMinutes / 60.0;
  }

  double hoursSince(DateTime since) {
    final effectiveStart = clockIn.isBefore(since) ? since : clockIn;
    final end = clockOut ?? DateTime.now();
    if (end.isBefore(effectiveStart)) return 0;
    return end.difference(effectiveStart).inMinutes / 60.0;
  }
}
