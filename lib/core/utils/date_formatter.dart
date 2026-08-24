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

  static const _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// e.g. `Senin, 24 Agu 2026` — the dashboard header's date line.
  static String longDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${_weekdays[local.weekday - 1]}, ${shortDate(local)} ${local.year}';
  }

  /// Coarse "how long ago" label for the dashboard's last-check line, e.g.
  /// `baru saja`, `2 jam lalu`, `3 hari lalu`. Falls back to [shortDate] past
  /// a week, where an exact date reads better than "31 hari lalu".
  static String relative(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return shortDate(dateTime);
  }

  /// Whether [dateTime] falls on the current local calendar day — the
  /// dashboard's "sudah dicek hari ini" test.
  static bool isToday(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  /// e.g. `07.12`.
  static String time(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  }
}
