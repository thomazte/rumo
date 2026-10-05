import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../state/scope.dart';
import '../../util/dates.dart';
import '../theme.dart';
import 'common.dart';

typedef OpenTask = void Function(String taskId);

class TaskList extends StatelessWidget {
  const TaskList(
    this.tasks, {
    super.key,
    required this.onOpen,
    this.showDate = false,
    this.showProject = true,
    this.selectedId,
    this.trailingBuilder,
  });

  final List<Task> tasks;
  final OpenTask onOpen;
  final bool showDate;
  final bool showProject;
  final String? selectedId;
  final Widget Function(Task task)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const Divider(),
          TaskTile(
            key: ValueKey(tasks[i].id),
            task: tasks[i],
            onOpen: () => onOpen(tasks[i].id),
            showDate: showDate,
            showProject: showProject,
            selected: tasks[i].id == selectedId,
            trailing: trailingBuilder?.call(tasks[i]),
          ),
        ],
      ],
    );
  }
}

class TaskTile extends StatefulWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onOpen,
    this.showDate = false,
    this.showProject = true,
    this.selected = false,
    this.trailing,
  });

  final Task task;
  final VoidCallback onOpen;
  final bool showDate;
  final bool showProject;
  final bool selected;
  final Widget? trailing;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  /// Mostra o check preenchido antes da tarefa sair da lista.
  bool? _optimisticDone;

  @override
  void didUpdateWidget(TaskTile old) {
    super.didUpdateWidget(old);
    if (old.task != widget.task) _optimisticDone = null;
  }

  void _toggle() {
    final store = context.store;
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.task.id;
    final done = !widget.task.done;
    setState(() => _optimisticDone = done);
    Future.delayed(Duration(milliseconds: done ? 380 : 0), () {
      store.setDone(id, done);
      if (done) showRumoSnack(messenger, 'Tarefa concluída', onUndo: () => store.setDone(id, false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final done = _optimisticDone ?? t.done;
    final rc = context.rc;
    final store = context.store;
    final project = store.project(t.projectId);
    final metaStyle = TextStyle(fontSize: 12, color: rc.muted);

    Widget meta(IconData icon, String? label, {Color? color, bool mono = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color ?? rc.muted),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: mono
                    ? monoStyle(context, size: 11.5, color: color ?? rc.muted)
                    : metaStyle.copyWith(color: color, fontWeight: color != null ? FontWeight.w600 : null),
              ),
            ],
          ],
        );

    final items = <Widget>[
      if (widget.showDate && t.date != null)
        meta(
          Icons.calendar_today_outlined,
          relativeDateLabel(t.date!, store.today),
          color: !t.done && t.date!.isBefore(store.today) ? rc.high : null,
        ),
      if (t.minutes != null) meta(Icons.schedule_rounded, formatMinutes(t.minutes!), mono: true),
      if (t.subtasks.isNotEmpty) meta(Icons.check_circle_outline_rounded, '${t.subtasksDone}/${t.subtasks.length}'),
      if (t.repeat != null) meta(Icons.repeat_rounded, t.repeat),
      if (t.notes.isNotEmpty) meta(Icons.notes_rounded, null),
      if (widget.showProject && project != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [ProjectDot(rc.project(project)), const SizedBox(width: 5), Text(project.name, style: metaStyle)],
        ),
    ];

    return Material(
      color: widget.selected ? context.cs.primaryContainer.withValues(alpha: 0.6) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriorityCheck(
                priority: t.priority,
                done: done,
                onTap: _toggle,
                semanticLabel: '${done ? 'Reabrir' : 'Concluir'}: ${t.title}',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: context.tt.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: done ? rc.muted : null,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: rc.muted,
                        ),
                        child: Text(t.title),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(spacing: 10, runSpacing: 3, children: items),
                      ],
                    ],
                  ),
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}
