import '../models/task.dart';
import 'dates.dart';

/// Resultado da captura rápida: "pagar aluguel sexta 9h #casa !alta".
class ParsedTask {
  const ParsedTask({
    required this.title,
    this.date,
    this.minutes,
    this.projectId,
    this.priority = Priority.none,
  });

  final String title;
  final DateTime? date;
  final int? minutes;
  final String? projectId;
  final Priority priority;
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

/// Minúsculas e sem acento, preservando o comprimento para que os índices
/// das buscas valham também no texto original.
String fold(String s) {
  final b = StringBuffer();
  for (final unit in s.split('')) {
    final lower = unit.toLowerCase();
    final l = lower.length == 1 ? lower : unit;
    b.write(_accents[l] ?? l);
  }
  return b.toString();
}

const _weekdays = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];

final _projectRe = RegExp(r'(^|\s)#([a-z0-9_-]+)');
final _priorityRe = RegExp(r'(^|\s)!(alta|media|baixa|[123])(?=\s|$)');
final _timeRe = RegExp(r'(^|\s)(?:as\s)?([01]?\d|2[0-3])(?:h([0-5]\d)?|:([0-5]\d))(?=\s|$)');
final _relativeRe = RegExp(r'(^|\s)(depois de amanha|amanha|hoje)(?=\s|$)');
final _weekdayRe = RegExp(
    r'(^|\s)(?:(?:na|no|ate|proxima|proximo)\s)*(domingo|segunda|terca|quarta|quinta|sexta|sabado)(?:-feira)?(?=\s|$)');
final _numericDateRe = RegExp(r'(^|\s)(?:dia\s)?(\d{1,2})/(\d{1,2})(?=\s|$)');

ParsedTask parseQuickEntry(String raw, {required List<Project> projects, required DateTime today}) {
  var text = raw;
  var folded = fold(raw);
  DateTime? date;
  int? minutes;
  String? projectId;
  var priority = Priority.none;

  // Aplica a primeira ocorrência e apaga o trecho do título.
  void take(RegExp re, bool Function(RegExpMatch m) apply) {
    final m = re.firstMatch(folded);
    if (m == null || !apply(m)) return;
    final blank = ' ' * (m.end - m.start);
    text = text.replaceRange(m.start, m.end, blank);
    folded = folded.replaceRange(m.start, m.end, blank);
  }

  take(_projectRe, (m) {
    final tag = m[2]!;
    for (final p in projects) {
      if (p.id.startsWith(tag) || fold(p.name).startsWith(tag)) {
        projectId = p.id;
        return true;
      }
    }
    return false;
  });

  take(_priorityRe, (m) {
    priority = switch (m[2]) {
      'alta' || '3' => Priority.high,
      'media' || '2' => Priority.medium,
      _ => Priority.low,
    };
    return true;
  });

  take(_timeRe, (m) {
    minutes = int.parse(m[2]!) * 60 + int.parse(m[3] ?? m[4] ?? '0');
    return true;
  });

  take(_relativeRe, (m) {
    date = addDays(today, switch (m[2]) { 'hoje' => 0, 'amanha' => 1, _ => 2 });
    return true;
  });

  if (date == null) {
    take(_weekdayRe, (m) {
      final target = _weekdays.indexOf(m[2]!);
      date = addDays(today, (target - weekdayIndex(today) + 7) % 7);
      return true;
    });
  }

  if (date == null) {
    take(_numericDateRe, (m) {
      final day = int.parse(m[2]!), month = int.parse(m[3]!);
      var d = DateTime(today.year, month, day);
      if (month < 1 || month > 12 || d.month != month) return false;
      if (d.isBefore(today)) d = DateTime(today.year + 1, month, day);
      date = d;
      return true;
    });
  }

  return ParsedTask(
    title: text.replaceAll(RegExp(r'\s+'), ' ').trim(),
    date: date,
    minutes: minutes,
    projectId: projectId,
    priority: priority,
  );
}
