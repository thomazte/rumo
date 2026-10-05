import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../models/task.dart';
import '../util/dates.dart';

class DayStats {
  const DayStats({required this.done, required this.total});

  final int done;
  final int total;

  int get left => total - done;
  double get progress => total == 0 ? 0 : done / total;
}

class TaskStore extends ChangeNotifier {
  TaskStore(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _clock;

  List<Task> _tasks = [];
  List<Project> _projects = defaultProjects;
  Timer? _saveTimer;
  int _seq = 0;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Project> get projects => List.unmodifiable(_projects);
  DateTime get today => dateOnly(_clock());

  Future<void> load() async {
    final data = await _repository.load();
    if (data == null) {
      _projects = defaultProjects;
      _tasks = _welcomeTasks();
      _scheduleSave();
    } else {
      _projects = data.projects.isEmpty ? defaultProjects : List.of(data.projects);
      _tasks = List.of(data.tasks);
    }
    notifyListeners();
  }

  /// Relê do disco o que outro processo salvou (ex.: tarefa concluída pelo widget).
  /// Não faz nada se houver alteração local ainda não salva.
  Future<void> reload() async {
    if (_saveTimer != null) return;
    // Um salvamento em andamento ainda não chegou ao disco.
    await _saving;
    final data = await _repository.load();
    if (data == null || _saveTimer != null) return;
    _projects = data.projects.isEmpty ? defaultProjects : List.of(data.projects);
    _tasks = List.of(data.tasks);
    notifyListeners();
  }

  String _newId() => '${_clock().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

  Project? project(String? id) {
    if (id == null) return null;
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Task? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---------- Alterações ----------

  Task add({
    required String title,
    DateTime? date,
    int? minutes,
    String? projectId,
    Priority priority = Priority.none,
  }) {
    final task = Task(
      id: _newId(),
      title: title,
      createdAt: _clock(),
      date: date == null ? null : dateOnly(date),
      minutes: minutes,
      projectId: projectId,
      priority: priority,
    );
    _tasks.add(task);
    _changed();
    return task;
  }

  void update(Task task) {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return;
    _tasks[i] = task;
    _changed();
  }

  void setDone(String id, bool done) {
    final t = byId(id);
    if (t == null || t.done == done) return;
    update(t.copyWith(done: done, doneAt: () => done ? today : null));
  }

  /// Remove e devolve o necessário para desfazer.
  ({Task task, int index})? delete(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    final task = _tasks.removeAt(i);
    _changed();
    return (task: task, index: i);
  }

  void restore(Task task, int index) {
    if (byId(task.id) != null) return;
    _tasks.insert(index.clamp(0, _tasks.length), task);
    _changed();
  }

  void _changed() {
    notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), flush);
  }

  Future<void>? _saving;

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final save = _repository.save(RumoData(projects: _projects, tasks: List.of(_tasks)));
    _saving = save;
    try {
      await save;
    } finally {
      if (identical(_saving, save)) _saving = null;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ---------- Consultas ----------

  /// Com data primeiro, depois quem tem horário, prioridade e título.
  static List<Task> sorted(Iterable<Task> tasks) {
    final list = tasks.toList();
    list.sort((a, b) {
      if (a.date != b.date) {
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      }
      if ((a.minutes == null) != (b.minutes == null)) return a.minutes == null ? 1 : -1;
      if (a.minutes != b.minutes) return a.minutes!.compareTo(b.minutes!);
      if (a.priority != b.priority) return b.priority.index.compareTo(a.priority.index);
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }

  Iterable<Task> get _open => _tasks.where((t) => !t.done);

  List<Task> overdue() => sorted(_open.where((t) => t.date != null && t.date!.isBefore(today)));

  List<Task> dueOn(DateTime day) => sorted(_open.where((t) => t.date != null && sameDay(t.date!, day)));

  List<Task> dueToday() => dueOn(today);

  List<Task> dueAfter(DateTime day) => sorted(_open.where((t) => t.date != null && t.date!.isAfter(day)));

  List<Task> completedToday() =>
      _tasks.where((t) => t.done && t.doneAt != null && sameDay(t.doneAt!, today)).toList();

  List<Task> inbox() => sorted(_open.where((t) => t.date == null && t.projectId == null));

  List<Task> ofProject(String id) => _tasks.where((t) => t.projectId == id).toList();

  /// Pendentes até hoje (inclui atrasadas) mais as concluídas hoje.
  DayStats todayStats() {
    final open = _open.where((t) => t.date != null && !t.date!.isAfter(today)).length;
    final done = completedToday().length;
    return DayStats(done: done, total: open + done);
  }

  /// A próxima com horário ainda hoje; senão a mais urgente.
  Task? nextTask() {
    final now = _clock();
    final nowMinutes = now.hour * 60 + now.minute;
    final pending = sorted(_open.where((t) => t.date != null && !t.date!.isAfter(today)));
    for (final t in pending) {
      if (sameDay(t.date!, today) && t.minutes != null && t.minutes! >= nowMinutes) return t;
    }
    for (final t in pending) {
      if (t.priority == Priority.high) return t;
    }
    return pending.firstOrNull;
  }

  /// Para onde a tarefa vai, em palavras: Hoje, Próximos, um projeto ou Inbox.
  String destinationOf({DateTime? date, String? projectId}) {
    if (date != null) return date.isAfter(today) ? 'Próximos' : 'Hoje';
    return project(projectId)?.name ?? 'Inbox';
  }

  // ---------- Primeira abertura ----------

  List<Task> _welcomeTasks() {
    Task make(String title, {int? inDays, Priority priority = Priority.none, String notes = '', List<Subtask> subtasks = const []}) =>
        Task(
          id: _newId(),
          title: title,
          createdAt: _clock(),
          date: inDays == null ? null : addDays(today, inDays),
          priority: priority,
          notes: notes,
          subtasks: subtasks,
        );

    return [
      make('Toque no círculo para concluir esta tarefa', inDays: 0, priority: Priority.low),
      make(
        'Abra esta tarefa para ver subtarefas e notas',
        inDays: 0,
        priority: Priority.medium,
        notes: 'Aqui ficam links, contexto e detalhes. Tudo é salvo sozinho.',
        subtasks: const [Subtask(title: 'Marque esta subtarefa'), Subtask(title: 'Adicione outra logo abaixo')],
      ),
      make(
        'Use o + e escreva: pagar aluguel sexta 9h #casa !alta',
        inDays: 0,
        priority: Priority.high,
        notes: 'Datas (hoje, amanhã, sexta, 12/10), horários (9h, 14:30), #projeto e '
            '!alta, !media ou !baixa são reconhecidos enquanto você escreve.\n\n'
            'No computador, Ctrl+N abre a captura de qualquer tela do app.',
      ),
      make('Escolha até 3 tarefas na aba Foco e rode um ciclo de 25 minutos', inDays: 1),
      make('Ideias sem data e sem projeto ficam na Inbox'),
    ];
  }
}
