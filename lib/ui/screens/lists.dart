import 'package:flutter/material.dart';

import '../../state/scope.dart';
import '../../state/task_store.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

const screenPadding = EdgeInsets.fromLTRB(20, 0, 20, 120);

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.onOpen, this.selectedId});

  final OpenTask onOpen;
  final String? selectedId;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final stats = store.todayStats();
    final overdue = store.overdue();
    final due = store.dueToday();
    final done = store.completedToday();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          eyebrow: longDate(store.today),
          title: 'Hoje',
          trailing: Semantics(
            label: '${stats.done} de ${stats.total} concluídas',
            child: ProgressRing(
              value: stats.progress,
              size: 56,
              child: Text('${stats.done}/${stats.total}', style: monoStyle(context, size: 12.5, weight: FontWeight.w600)),
            ),
          ),
        ),
        if (overdue.isNotEmpty) ...[
          SectionHeader('Atrasadas', count: '${overdue.length}', color: context.rc.high),
          TaskList(overdue, onOpen: widget.onOpen, showDate: true, selectedId: widget.selectedId),
        ],
        if (due.isNotEmpty) ...[
          if (overdue.isNotEmpty) SectionHeader('Para hoje', count: '${due.length}') else const SizedBox(height: 8),
          TaskList(due, onOpen: widget.onOpen, selectedId: widget.selectedId),
        ],
        if (overdue.isEmpty && due.isEmpty)
          const EmptyState(title: 'Tudo feito por hoje', message: 'Adicione algo com o + ou aproveite o resto do dia.'),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showDone = !_showDone),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text('${_showDone ? 'Ocultar' : 'Mostrar'} concluídas (${done.length})'),
            ),
          ),
          if (_showDone) TaskList(done, onOpen: widget.onOpen, selectedId: widget.selectedId),
        ],
      ],
    );
  }
}

class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key, required this.onOpen, this.selectedId});

  final OpenTask onOpen;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final today = store.today;
    final later = store.dueAfter(addDays(today, 7));

    return ListView(
      padding: screenPadding,
      children: [
        const ScreenHeader(eyebrow: 'Próximos 7 dias', title: 'Próximos'),
        for (var i = 1; i <= 7; i++)
          Builder(builder: (context) {
            final day = addDays(today, i);
            final tasks = store.dueOn(day);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  i == 1 ? 'Amanhã' : capitalize(weekdayNames[weekdayIndex(day)]),
                  subtitle: shortDate(day),
                  count: tasks.isEmpty ? null : '${tasks.length}',
                ),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Nada planejado', style: TextStyle(color: context.rc.muted, fontSize: 13)),
                  )
                else
                  TaskList(tasks, onOpen: onOpen, selectedId: selectedId),
              ],
            );
          }),
        if (later.isNotEmpty) ...[
          SectionHeader('Mais adiante', count: '${later.length}'),
          TaskList(later, onOpen: onOpen, showDate: true, selectedId: selectedId),
        ],
      ],
    );
  }
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key, required this.onOpen, this.selectedId});

  final OpenTask onOpen;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.store.inbox();
    return ListView(
      padding: screenPadding,
      children: [
        const ScreenHeader(eyebrow: 'Sem data e sem projeto', title: 'Inbox'),
        Text(
          'Jogue aqui tudo que surgir. Depois abra cada item e dê um dia ou um projeto para ele.',
          style: TextStyle(color: context.rc.muted, fontSize: 13.5, height: 1.45),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const EmptyState(title: 'Inbox vazia', message: 'Tudo que entrou já tem lugar.', icon: Icons.inbox_outlined)
        else
          TaskList(tasks, onOpen: onOpen, selectedId: selectedId),
      ],
    );
  }
}

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.onOpenProject});

  final ValueChanged<String> onOpenProject;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final rc = context.rc;
    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(eyebrow: '${store.projects.length} áreas', title: 'Projetos'),
        const SizedBox(height: 8),
        for (final p in store.projects)
          Builder(builder: (context) {
            final all = store.ofProject(p.id);
            final done = all.where((t) => t.done).length;
            final pending = all.length - done;
            final next = TaskStore.sorted(all.where((t) => !t.done)).firstOrNull;
            final color = rc.project(p);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: rc.surface2,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onOpenProject(p.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProjectDot(color, size: 12),
                            const SizedBox(width: 10),
                            Expanded(child: Text(p.name, style: context.tt.titleMedium)),
                            Text('$pending ${pending == 1 ? 'pendente' : 'pendentes'}',
                                style: monoStyle(context, color: rc.muted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: all.isEmpty ? 0 : done / all.length,
                            minHeight: 6,
                            color: color,
                            backgroundColor: rc.line,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          next == null ? 'Nada pendente' : 'Próxima: ${next.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: rc.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key, required this.projectId, required this.onBack, required this.onOpen, this.selectedId});

  final String projectId;
  final VoidCallback onBack;
  final OpenTask onOpen;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final project = store.project(projectId);
    if (project == null) return const SizedBox.shrink();
    final all = store.ofProject(projectId);
    final pending = TaskStore.sorted(all.where((t) => !t.done));
    final done = all.where((t) => t.done).toList();

    return ListView(
      padding: screenPadding,
      children: [
        ScreenHeader(
          leading: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Projetos'),
            style: TextButton.styleFrom(padding: const EdgeInsets.only(right: 8), visualDensity: VisualDensity.compact),
          ),
          eyebrow: '${pending.length} pendentes',
          title: project.name,
          titleColorDot: context.rc.project(project),
        ),
        if (pending.isEmpty)
          const EmptyState(title: 'Nada pendente', message: 'Use o + para adicionar algo a este projeto.')
        else ...[
          const SizedBox(height: 8),
          TaskList(pending, onOpen: onOpen, showDate: true, showProject: false, selectedId: selectedId),
        ],
        if (done.isNotEmpty) ...[
          SectionHeader('Concluídas', count: '${done.length}'),
          TaskList(done, onOpen: onOpen, showProject: false, selectedId: selectedId),
        ],
      ],
    );
  }
}
