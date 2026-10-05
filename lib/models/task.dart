import '../util/dates.dart';

enum Priority {
  none,
  low,
  medium,
  high;

  String get label => const ['Nenhuma', 'Baixa', 'Média', 'Alta'][index];
}

class Project {
  const Project({required this.id, required this.name, required this.color});

  final String id;
  final String name;

  /// Chave da paleta de projetos (ver `projectColor` em theme.dart).
  final String color;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String? ?? 'blue',
      );
}

const defaultProjects = [
  Project(id: 'trabalho', name: 'Trabalho', color: 'blue'),
  Project(id: 'casa', name: 'Casa', color: 'orange'),
  Project(id: 'saude', name: 'Saúde', color: 'green'),
  Project(id: 'estudos', name: 'Estudos', color: 'violet'),
];

class Subtask {
  const Subtask({required this.title, this.done = false});

  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  factory Subtask.fromJson(Map<String, dynamic> json) =>
      Subtask(title: json['title'] as String, done: json['done'] as bool? ?? false);
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.date,
    this.minutes,
    this.projectId,
    this.priority = Priority.none,
    this.done = false,
    this.doneAt,
    this.notes = '',
    this.subtasks = const [],
    this.repeat,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  /// Dia da tarefa (sem horário). Nulo = sem data.
  final DateTime? date;

  /// Horário em minutos desde a meia-noite. Nulo = sem horário.
  final int? minutes;
  final String? projectId;
  final Priority priority;
  final bool done;

  /// Dia em que foi concluída.
  final DateTime? doneAt;
  final String notes;
  final List<Subtask> subtasks;

  /// Descrição da recorrência, por enquanto só exibida.
  final String? repeat;

  int get subtasksDone => subtasks.where((s) => s.done).length;

  Task copyWith({
    String? title,
    DateTime? Function()? date,
    int? Function()? minutes,
    String? Function()? projectId,
    Priority? priority,
    bool? done,
    DateTime? Function()? doneAt,
    String? notes,
    List<Subtask>? subtasks,
    String? Function()? repeat,
  }) =>
      Task(
        id: id,
        createdAt: createdAt,
        title: title ?? this.title,
        date: date != null ? date() : this.date,
        minutes: minutes != null ? minutes() : this.minutes,
        projectId: projectId != null ? projectId() : this.projectId,
        priority: priority ?? this.priority,
        done: done ?? this.done,
        doneAt: doneAt != null ? doneAt() : this.doneAt,
        notes: notes ?? this.notes,
        subtasks: subtasks ?? this.subtasks,
        repeat: repeat != null ? repeat() : this.repeat,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        if (date != null) 'date': isoDate(date!),
        if (minutes != null) 'minutes': minutes,
        if (projectId != null) 'projectId': projectId,
        'priority': priority.name,
        'done': done,
        if (doneAt != null) 'doneAt': isoDate(doneAt!),
        if (notes.isNotEmpty) 'notes': notes,
        if (subtasks.isNotEmpty) 'subtasks': [for (final s in subtasks) s.toJson()],
        if (repeat != null) 'repeat': repeat,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        date: json['date'] == null ? null : parseIsoDate(json['date'] as String),
        minutes: json['minutes'] as int?,
        projectId: json['projectId'] as String?,
        priority: Priority.values.asNameMap()[json['priority']] ?? Priority.none,
        done: json['done'] as bool? ?? false,
        doneAt: json['doneAt'] == null ? null : parseIsoDate(json['doneAt'] as String),
        notes: json['notes'] as String? ?? '',
        subtasks: [
          for (final s in (json['subtasks'] as List? ?? const []))
            Subtask.fromJson(s as Map<String, dynamic>),
        ],
        repeat: json['repeat'] as String?,
      );
}
