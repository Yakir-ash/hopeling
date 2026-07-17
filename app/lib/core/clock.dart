// The ONE place dates are computed (NATIVE.md rule).
// Must produce results identical to the PWA's core.js - verified in tests.

String todayStr([DateTime? now]) {
  final n = now ?? DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// Identical to core.js: h = (h*31 + charCode) >>> 0, over date+salt.
int dailyIndex(int len, String salt, [DateTime? now]) {
  final d = todayStr(now) + salt;
  var h = 0;
  for (var i = 0; i < d.length; i++) {
    h = ((h * 31) + d.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return h % len;
}

/// Date strings must compute in UTC: Dart parses date-only strings as
/// LOCAL midnight, which makes DST transition days 23 or 25 hours long
/// and corrupts day counts. Forcing Z makes every day exactly 24h.
DateTime _utcDay(String d) => DateTime.parse('${d}T00:00:00Z');

/// Whole civil days between two YYYY-MM-DD strings (b - a). DST-proof.
int daysBetween(String a, String b) =>
    _utcDay(b).difference(_utcDay(a)).inDays;

/// A civil date plus/minus whole days. DST-proof.
String addDays(String day, int n) {
  final d = _utcDay(day).add(Duration(days: n));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
