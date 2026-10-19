import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_mobile/domain/duration_calc.dart';

DateTime d(int day, int h, int m) => DateTime(2026, 10, day, h, m);
int hm(int h, int m) => h * 60 + m;

void main() {
  group('Zorunlu testler', () {
    test('T1 08:00-16:00', () {
      final r = calculateTask(d(1, 8, 0), d(1, 16, 0));
      expect(r.totalMinutes, hm(8, 0));
      expect(r.nightMinutes, 0);
      expect(r.nightExcessMinutes, 0);
    });
    test('T2 13:00-ertesi 05:15', () {
      final r = calculateTask(d(1, 13, 0), d(2, 5, 15));
      expect(r.totalMinutes, hm(16, 15));
      expect(r.nightMinutes, hm(9, 15));
      expect(r.nightExcessMinutes, hm(1, 45));
    });
    test('T3 (45 modeli süresi) 14:30-ertesi 04:45', () {
      final r = calculateTask(d(1, 14, 30), d(2, 4, 45));
      expect(r.totalMinutes, hm(14, 15));
      expect(r.nightMinutes, hm(8, 45));
      expect(r.nightExcessMinutes, hm(1, 15));
    });
    test('T4 22:00-ertesi 08:00 (gece 22-06 = 8 sa, aşım 30 dk)', () {
      final r = calculateTask(d(1, 22, 0), d(2, 8, 0));
      expect(r.totalMinutes, hm(10, 0));
      expect(r.nightMinutes, hm(8, 0));
      expect(r.nightExcessMinutes, 30);
    });
    test('T5 15:00-ertesi 08:00', () {
      final r = calculateTask(d(1, 15, 0), d(2, 8, 0));
      expect(r.totalMinutes, hm(17, 0));
      expect(r.nightMinutes, hm(10, 0));
      expect(r.nightExcessMinutes, hm(2, 30));
    });
    test('T6 21:00-ertesi 03:00 sınır altı', () {
      final r = calculateTask(d(1, 21, 0), d(2, 3, 0));
      expect(r.totalMinutes, hm(6, 0));
      expect(r.nightMinutes, hm(6, 0));
      expect(r.nightExcessMinutes, 0);
    });
    test('T7 aynı gün iki görev toplamı 10 sa 30 dk', () {
      final a = calculateTask(d(1, 9, 0), d(1, 17, 0));
      final b = calculateTask(d(1, 21, 0), d(1, 23, 30));
      expect(a.totalMinutes + b.totalMinutes, hm(10, 30));
    });
    test('T12 ay değişimi 31 Ekim 22:00 - 1 Kasım 06:00', () {
      final r = calculateTask(
          DateTime(2026, 10, 31, 22, 0), DateTime(2026, 11, 1, 6, 0));
      expect(r.totalMinutes, hm(8, 0));
      expect(r.nightMinutes, hm(8, 0));
    });
    test('T17 05:00-07:00 gece 1 sa', () {
      final r = calculateTask(d(1, 5, 0), d(1, 7, 0));
      expect(r.totalMinutes, hm(2, 0));
      expect(r.nightMinutes, hm(1, 0));
    });
    test('T18 birden fazla gece', () {
      // 1 Ekim 18:00 - 3 Ekim 10:00 = 40 sa; 2 gece x 10 sa = 20 sa
      final r = calculateTask(d(1, 18, 0), d(3, 10, 0));
      expect(r.totalMinutes, hm(40, 0));
      expect(r.nightMinutes, hm(20, 0));
    });
  });

  test('Örnek ay (31. madde): toplam 78 sa, gece 30 sa 30 dk, aşım 5 sa 30 dk',
      () {
    // Not: 21:00-23:30 görevi tamamen gece aralığındadır (2 sa 30 dk),
    // bu yüzden gece toplamı şartnamedeki 28 sa değil 30 sa 30 dk olur.
    final tasks = <List<DateTime>>[
      [d(1, 8, 0), d(1, 16, 0)],
      [d(2, 13, 0), d(3, 5, 15)],
      [d(4, 14, 30), d(5, 4, 45)],
      [d(6, 9, 0), d(6, 17, 0)],
      [d(6, 21, 0), d(6, 23, 30)],
      [d(8, 15, 0), d(9, 8, 0)],
      [d(10, 6, 0), d(10, 14, 0)],
      [d(11, 9, 0), d(11, 13, 0)],
    ];
    var total = 0, night = 0, excess = 0;
    for (final t in tasks) {
      final r = calculateTask(t[0], t[1]);
      total += r.totalMinutes;
      night += r.nightMinutes;
      excess += r.nightExcessMinutes;
    }
    expect(total, hm(78, 0));
    expect(night, hm(30, 30));
    expect(excess, hm(5, 30));
  });

  test('Geçersiz aralık sessizce kabul edilmez', () {
    expect(() => calculateTask(d(1, 10, 0), d(1, 10, 0)), throwsArgumentError);
    expect(() => calculateTask(d(1, 10, 0), d(1, 9, 0)), throwsArgumentError);
  });

  test('Saat girişi biçimleri', () {
    expect(parseClockToMinutes('22:00'), hm(22, 0));
    expect(parseClockToMinutes('22.00'), hm(22, 0));
    expect(parseClockToMinutes('8:05'), hm(8, 5));
    expect(parseClockToMinutes('08:05'), hm(8, 5));
    expect(parseClockToMinutes('2200'), hm(22, 0));
    expect(parseClockToMinutes('2560'), isNull);
    expect(parseClockToMinutes('abc'), isNull);
  });

  test('formatMinutes 60 dk saate aktarır', () {
    expect(formatMinutes(hm(16, 15)), '16 sa 15 dk');
    expect(formatMinutes(125), '2 sa 5 dk');
  });
}
