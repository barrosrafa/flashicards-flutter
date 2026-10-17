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

  static String dateOnly(DateTime date) {
    return date.toUtc().toIso8601String().substring(0, 10);
  }

  static DateRangeBounds forDays(int days, [DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final end = DateTime.utc(current.year, current.month, current.day);
    final start = end.subtract(Duration(days: days - 1));
    final until = end.add(const Duration(days: 1));
    return DateRangeBounds(
      startDate: dateOnly(start),
      endDate: dateOnly(end),
      since: start.toIso8601String(),
      until: until.toIso8601String(),
    );
  }
}
