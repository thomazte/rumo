// Datas tratadas sempre como "dia local", sem horário.

const weekdayNames = ['domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'];
const weekdayShort = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
const monthShort = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
const monthLong = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Diferença em dias de calendário (imune a horário de verão).
int dayDiff(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
    .difference(DateTime.utc(from.year, from.month, from.day))
    .inDays;

/// Índice 0 = domingo, igual às listas acima.
int weekdayIndex(DateTime d) => d.weekday % 7;

String _two(int n) => n.toString().padLeft(2, '0');

String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

DateTime parseIsoDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "segunda-feira, 5 de outubro"
String longDate(DateTime d) {
  final i = weekdayIndex(d);
  final suffix = i >= 1 && i <= 5 ? '-feira' : '';
  return '${weekdayNames[i]}$suffix, ${d.day} de ${monthLong[d.month - 1]}';
}

String shortDate(DateTime d) => '${d.day} ${monthShort[d.month - 1]}';

/// Hoje, Amanhã, Ontem, Qua (até 6 dias) ou "12 out".
String relativeDateLabel(DateTime d, DateTime today) {
  final n = dayDiff(today, d);
  if (n == 0) return 'Hoje';
  if (n == 1) return 'Amanhã';
  if (n == -1) return 'Ontem';
  if (n > 1 && n < 7) return capitalize(weekdayShort[weekdayIndex(d)]);
  return shortDate(d);
}

String formatMinutes(int m) => '${_two(m ~/ 60)}:${_two(m % 60)}';

String formatClock(Duration d) => '${_two(d.inMinutes)}:${_two(d.inSeconds % 60)}';

DateTime nextMonday(DateTime today) {
  final add = (8 - today.weekday) % 7;
  return addDays(today, add == 0 ? 7 : add);
}
