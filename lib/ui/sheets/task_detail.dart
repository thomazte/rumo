import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../state/scope.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';

Future<void> showTaskDetailSheet(BuildContext context, String taskId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: TaskDetailView(
          taskId: taskId,
          scrollController: scroll,
          onClose: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    ),
  );
}

/// Edição completa de uma tarefa. Usada na folha (celular) e no painel lateral (tela larga).
class TaskDetailView extends StatefulWidget {
  const TaskDetailView({super.key, required this.taskId, required this.onClose, this.scrollController});

  final String taskId;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _subtask = TextEditingController();
  final _subtaskFocus = FocusNode();
  bool _armedDelete = false;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  @override
  void didUpdateWidget(TaskDetailView old) {
    super.didUpdateWidget(old);
    if (old.taskId != widget.taskId) {
      _armedDelete = false;
      _subtask.clear();
      _loadText();
    }
  }

  void _loadText() {
    final t = context.store.byId(widget.taskId);
    _title.text = t?.title ?? '';
    _notes.text = t?.notes ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _subtask.dispose();
    _subtaskFocus.dispose();
    super.dispose();
  }

  void _addSubtask(Task t) {
    final title = _subtask.text.trim();
    if (title.isEmpty) return;
    context.store.update(t.copyWith(subtasks: [...t.subtasks, Subtask(title: title)]));
    _subtask.clear();
    _subtaskFocus.requestFocus();
  }

  Future<void> _pickDate(Task t) async {
    final today = context.store.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: t.date ?? today,
      firstDate: addDays(today, -365),
      lastDate: addDays(today, 365 * 5),
    );
    if (picked != null && mounted) context.store.update(t.copyWith(date: () => dateOnly(picked)));
  }

  Future<void> _pickTime(Task t) async {
    final m = t.minutes ?? 9 * 60;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (picked == null || !mounted) return;
    final current = context.store.byId(t.id) ?? t;
    context.store.update(current.copyWith(
      minutes: () => picked.hour * 60 + picked.minute,
      // Horário sem dia não faz sentido: assume hoje.
      date: current.date == null ? () => context.store.today : null,
    ));
  }

  void _delete(Task t) {
    if (!_armedDelete) {
      setState(() => _armedDelete = true);
      return;
    }
    final store = context.store;
    final messenger = ScaffoldMessenger.of(context);
    final removed = store.delete(t.id);
    widget.onClose();
    if (removed != null) {
      showRumoSnack(messenger, 'Tarefa excluída', onUndo: () => store.restore(removed.task, removed.index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.byId(widget.taskId);
        if (t == null) return const SizedBox.shrink();
        final rc = context.rc;
        final today = store.today;
        final presets = <(String, DateTime?)>[
          ('Hoje', today),
          ('Amanhã', addDays(today, 1)),
          ('Próx. segunda', nextMonday(today)),
          ('Sem data', null),
        ];
        final matchesPreset = presets.any((p) => p.$2 == null ? t.date == null : t.date != null && sameDay(t.date!, p.$2!));

        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: PriorityCheck(
                    priority: t.priority,
                    done: t.done,
                    size: 26,
                    semanticLabel: t.done ? 'Reabrir' : 'Concluir',
                    onTap: () => store.setDone(t.id, !t.done),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _title,
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    style: context.tt.headlineSmall?.copyWith(
                      decoration: t.done ? TextDecoration.lineThrough : null,
                      color: t.done ? rc.muted : null,
                    ),
                    decoration: const InputDecoration.collapsed(hintText: 'Título'),
                    onChanged: (v) {
                      final title = v.replaceAll('\n', ' ');
                      if (title.trim().isNotEmpty) store.update(t.copyWith(title: title));
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded, color: rc.muted),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                    label: 'Quando',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (label, date) in presets)
                          ChoiceChip(
                            label: Text(label),
                            selected: date == null ? t.date == null : t.date != null && sameDay(t.date!, date),
                            onSelected: (_) => store.update(t.copyWith(
                              date: () => date,
                              minutes: date == null ? () => null : null,
                            )),
                          ),
                        ChoiceChip(
                          avatar: const Icon(Icons.calendar_today_outlined, size: 15),
                          label: Text(!matchesPreset && t.date != null ? shortDate(t.date!) : 'Escolher data'),
                          selected: !matchesPreset,
                          onSelected: (_) => _pickDate(t),
                        ),
                        if (t.minutes == null)
                          ActionChip(
                            avatar: const Icon(Icons.schedule_rounded, size: 15),
                            label: const Text('Horário'),
                            onPressed: () => _pickTime(t),
                          )
                        else
                          InputChip(
                            avatar: const Icon(Icons.schedule_rounded, size: 15),
                            label: Text(formatMinutes(t.minutes!), style: monoStyle(context, size: 13)),
                            onPressed: () => _pickTime(t),
                            onDeleted: () => store.update(t.copyWith(minutes: () => null)),
                            deleteButtonTooltipMessage: 'Tirar horário',
                          ),
                      ],
                    ),
                  ),
                  _Field(
                    label: 'Prioridade',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in Priority.values.reversed)
                          ChoiceChip(
                            avatar: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: rc.priority(p), shape: BoxShape.circle),
                            ),
                            label: Text(p.label),
                            selected: t.priority == p,
                            onSelected: (_) => store.update(t.copyWith(priority: p)),
                          ),
                      ],
                    ),
                  ),
                  _Field(
                    label: 'Projeto',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in store.projects)
                          ChoiceChip(
                            avatar: ProjectDot(rc.project(p)),
                            label: Text(p.name),
                            selected: t.projectId == p.id,
                            onSelected: (_) => store.update(t.copyWith(projectId: () => p.id)),
                          ),
                        ChoiceChip(
                          label: const Text('Nenhum'),
                          selected: t.projectId == null,
                          onSelected: (_) => store.update(t.copyWith(projectId: () => null)),
                        ),
                      ],
                    ),
                  ),
                  _Field(
                    label: 'Subtarefas',
                    count: t.subtasks.isEmpty ? null : '${t.subtasksDone}/${t.subtasks.length}',
                    child: Column(
                      children: [
                        for (var i = 0; i < t.subtasks.length; i++)
                          Row(
                            children: [
                              PriorityCheck(
                                priority: Priority.none,
                                done: t.subtasks[i].done,
                                size: 19,
                                onTap: () {
                                  final subs = [...t.subtasks];
                                  subs[i] = subs[i].copyWith(done: !subs[i].done);
                                  store.update(t.copyWith(subtasks: subs));
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.subtasks[i].title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: t.subtasks[i].done ? rc.muted : null,
                                    decoration: t.subtasks[i].done ? TextDecoration.lineThrough : null,
                                    decorationColor: rc.muted,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remover subtarefa',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.close_rounded, size: 16, color: rc.muted),
                                onPressed: () => store.update(t.copyWith(subtasks: [...t.subtasks]..removeAt(i))),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        _Box(
                          child: TextField(
                            controller: _subtask,
                            focusNode: _subtaskFocus,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration.collapsed(hintText: 'Nova subtarefa, Enter para adicionar'),
                            onSubmitted: (_) => _addSubtask(t),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Field(
                    label: 'Notas',
                    child: _Box(
                      child: TextField(
                        controller: _notes,
                        minLines: 3,
                        maxLines: 10,
                        style: const TextStyle(fontSize: 14, height: 1.45),
                        decoration: const InputDecoration.collapsed(hintText: 'Links, contexto, detalhes'),
                        onChanged: (v) => store.update(t.copyWith(notes: v)),
                      ),
                    ),
                  ),
                  if (t.repeat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Icon(Icons.repeat_rounded, size: 16, color: rc.muted),
                          const SizedBox(width: 6),
                          Text('Repete: ${t.repeat}', style: TextStyle(color: rc.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  TextButton.icon(
                    onPressed: () => _delete(t),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    label: Text(_armedDelete ? 'Toque de novo para excluir' : 'Excluir tarefa'),
                    style: TextButton.styleFrom(
                      foregroundColor: rc.high,
                      backgroundColor: rc.high.withValues(alpha: 0.1),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.count});

  final String label;
  final String? count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(), style: context.tt.labelSmall?.copyWith(color: context.rc.muted)),
              if (count != null) ...[
                const SizedBox(width: 8),
                Text(count!, style: monoStyle(context, size: 11.5, color: context.rc.muted)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: context.rc.surface2,
          border: Border.all(color: context.rc.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
}
