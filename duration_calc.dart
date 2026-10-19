/// Merkezi süre hesaplama motoru (Aşama 2).
/// Tüm hesaplar TAM DAKİKA üzerinden yapılır; kayan noktalı sayı kullanılmaz.
/// Arayüzden bağımsızdır.

/// Gece çalışma aralığı: 20:00–06:00 (her takvim gününe uygulanır).
const int nightStartHour = 20;
const int nightEndHour = 6;

/// Gece çalışma sınırı: 7 saat 30 dakika = 450 dakika.
const int nightLimitMinutes = 450;

class TaskCalc {
  /// Bitiş − Başlangıç (dakika).
  final int totalMinutes;

  /// Görev aralığının 20:00–06:00 ile kesişen toplamı (dakika).
  final int nightMinutes;

  /// max(0, gece − 450). Genel fazla mesai DEĞİLDİR; ayrı kalemdir.
  final int nightExcessMinutes;

  const TaskCalc({
    required this.totalMinutes,
    required this.nightMinutes,
    required this.nightExcessMinutes,
  });

  @override
  String toString() =>
      'TaskCalc(toplam: ${formatMinutes(totalMinutes)}, '
      'gece: ${formatMinutes(nightMinutes)}, '
      'gece aşımı: ${formatMinutes(nightExcessMinutes)})';
}

/// Dakikayı "16 sa 15 dk" biçiminde yazar. 60 dakika saate aktarılır.
String formatMinutes(int minutes) {
  final neg = minutes < 0;
  final m = minutes.abs();
  final h = m ~/ 60;
  final r = m % 60;
  return '${neg ? '-' : ''}$h sa $r dk';
}

/// Duvar saatini saat dilimi/yaz saati etkisinden arındırır.
DateTime _wall(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day, d.hour, d.minute);

int _overlapMinutes(DateTime aS, DateTime aE, DateTime bS, DateTime bE) {
  final s = aS.isAfter(bS) ? aS : bS;
  final e = aE.isBefore(bE) ? aE : bE;
  return e.isAfter(s) ? e.difference(s).inMinutes : 0;
}

/// Görevin gece çalışma dakikası: her gecenin kesişimi ayrı hesaplanıp toplanır.
int nightMinutesBetween(DateTime start, DateTime end) {
  final s = _wall(start);
  final e = _wall(end);
  if (!e.isAfter(s)) return 0;
  var day =
      DateTime.utc(s.year, s.month, s.day).subtract(const Duration(days: 1));
  final lastDay = DateTime.utc(e.year, e.month, e.day);
  var total = 0;
  while (!day.isAfter(lastDay)) {
    final ws = DateTime.utc(day.year, day.month, day.day, nightStartHour);
    final we = DateTime.utc(day.year, day.month, day.day + 1, nightEndHour);
    total += _overlapMinutes(s, e, ws, we);
    day = day.add(const Duration(days: 1));
  }
  return total;
}

/// Bir görevin süre, gece ve gece aşımı hesabı.
/// Bitiş başlangıçtan önce veya eşitse [ArgumentError] fırlatır (sessiz kabul yok).
TaskCalc calculateTask(DateTime start, DateTime end) {
  final s = _wall(start);
  final e = _wall(end);
  if (!e.isAfter(s)) {
    throw ArgumentError('Bitiş zamanı başlangıçtan sonra olmalıdır.');
  }
  final total = e.difference(s).inMinutes;
  final night = nightMinutesBetween(start, end);
  final excess = night > nightLimitMinutes ? night - nightLimitMinutes : 0;
  return TaskCalc(
    totalMinutes: total,
    nightMinutes: night,
    nightExcessMinutes: excess,
  );
}

/// "22:00", "22.00", "8:05", "08:05", "2200" → günün dakikası. Geçersizse null.
int? parseClockToMinutes(String input) {
  final t = input.trim();
  int? h;
  int? m;
  final sep = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(t);
  if (sep != null) {
    h = int.parse(sep.group(1)!);
    m = int.parse(sep.group(2)!);
  } else {
    final compact = RegExp(r'^(\d{2})(\d{2})$').firstMatch(t);
    if (compact != null) {
      h = int.parse(compact.group(1)!);
      m = int.parse(compact.group(2)!);
    }
  }
  if (h == null || m == null) return null;
  if (h > 23 || m > 59) return null;
  return h * 60 + m;
}
