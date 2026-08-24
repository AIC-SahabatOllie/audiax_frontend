/// Small Indonesian date helpers for API timestamps (`docs/api_contract.md`
/// ISO8601 fields) — no `intl` dependency needed for the couple of formats
/// the UI uses.
class DateFormatter {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// e.g. `2 Agu`.
  static String shortDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day} ${_months[local.month - 1]}';
  }

  /// e.g. `07.12`.
  static String time(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  }
}
