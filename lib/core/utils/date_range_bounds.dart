/// Cálculo de janelas de datas em UTC compatível com `rangeDateBounds`
/// em `lib/services/analytics-service.ts`.
class DateRangeBounds {
  const DateRangeBounds({
    required this.startDate,
    required this.endDate,
    required this.since,
    required this.until,
  });

  final String startDate;
  final String endDate;
  final String since;
  final String until;

  String get startIsoDate => startDate;
  String get endIsoDate => endDate;

  static String dateOnly(DateTime date) {
    return date.toUtc().toIso8601String().substring(0, 10);
  }

  static DateRangeBounds forDays([
    int days = 30,
    DateTime? now,
    int? daysBack,
  ]) {
    final int effectiveDays = (daysBack ?? days).clamp(1, 3650);
    final DateTime current = (now ?? DateTime.now()).toUtc();
    final DateTime end = DateTime.utc(current.year, current.month, current.day);
    final DateTime start = end.subtract(Duration(days: effectiveDays - 1));
    final DateTime until = end.add(const Duration(days: 1));
    return DateRangeBounds(
      startDate: dateOnly(start),
      endDate: dateOnly(end),
      since: start.toIso8601String(),
      until: until.toIso8601String(),
    );
  }
}
