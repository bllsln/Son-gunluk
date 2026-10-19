import 'package:flutter/material.dart';
import 'domain/duration_calc.dart';

void main() => runApp(const GunlukMobileApp());

class GunlukMobileApp extends StatelessWidget {
  const GunlukMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Günlük-Mobile',
      themeMode: ThemeMode.system,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true),
      home: const CalcPreviewPage(),
    );
  }
}

/// Aşama 2 önizleme ekranı: hesap motorunu telefonda elle denemek içindir.
/// Henüz veri kaydetmez.
class CalcPreviewPage extends StatefulWidget {
  const CalcPreviewPage({super.key});

  @override
  State<CalcPreviewPage> createState() => _CalcPreviewPageState();
}

class _CalcPreviewPageState extends State<CalcPreviewPage> {
  static DateTime _now() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour, n.minute);
  }

  DateTime _start = _now();
  DateTime _end = _now().add(const Duration(hours: 8));

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    TaskCalc? result;
    String? error;
    try {
      result = calculateTask(_start, _end);
    } on ArgumentError catch (e) {
      error = e.message.toString();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('GÜNLÜK-MOBILE – Raylar Arasında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Başlangıç'),
              subtitle: Text(_fmt(_start)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final v = await _pick(_start);
                if (v != null) setState(() => _start = v);
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Bitiş'),
              subtitle: Text(_fmt(_end)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final v = await _pick(_end);
                if (v != null) setState(() => _end = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          if (error != null)
            Text(error,
                style: TextStyle(color: Theme.of(context).colorScheme.error))
          else if (result != null) ...[
            _row('Toplam görev süresi', formatMinutes(result.totalMinutes)),
            _row('Gece çalışması (20:00–06:00)',
                formatMinutes(result.nightMinutes)),
            _row('Gece sınırı', formatMinutes(nightLimitMinutes)),
            _row('Gece çalışma aşımı',
                formatMinutes(result.nightExcessMinutes)),
          ],
          const SizedBox(height: 16),
          const Text(
            'Önizleme sürümü: kayıt tutmaz. Genel fazla mesai kuralı '
            'doğrulanmadığı için hesaplanmaz.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(a)),
            Text(b, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
