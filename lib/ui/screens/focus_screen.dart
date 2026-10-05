import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../platform/desktop.dart';
import '../../state/focus_timer.dart';
import '../../state/scope.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';
import 'lists.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, required this.onOpen, this.selectedId});

  final OpenTask onOpen;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final timer = context.focusTimer;
    final store = context.store;
    final rc = context.rc;

    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final selected = [for (final id in timer.selected) store.byId(id)].whereType<Task>().toList();
        final candidates = [...store.overdue(), ...store.dueToday()].where((t) => !timer.isSelected(t.id)).toList();
        final current = selected.where((t) => !t.done).firstOrNull;
        final pause = timer.mode == FocusMode.pause;
        final label = pause
            ? 'Levante, beba água'
            : current?.title ?? (selected.isEmpty ? 'Escolha uma tarefa abaixo' : 'Tudo feito');

        return ListView(
          padding: screenPadding,
          children: [
            ScreenHeader(
              eyebrow: 'Pomodoro',
              title: 'Foco',
              trailing: Semantics(
                label: '${timer.cycles} ciclos hoje',
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        margin: const EdgeInsets.only(left: 6, bottom: 10),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < timer.cycles ? context.cs.primary : rc.ringTrack,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<FocusMode>(
                segments: const [
                  ButtonSegment(value: FocusMode.focus, label: Text('Foco 25 min')),
                  ButtonSegment(value: FocusMode.pause, label: Text('Pausa 5 min')),
                ],
                selected: {timer.mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => timer.setMode(s.first),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ProgressRing(
                value: timer.progress,
                size: 216,
                stroke: 12,
                color: pause ? rc.low : null,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatClock(timer.remaining), style: monoStyle(context, size: 46, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: rc.muted, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: timer.reset,
                  tooltip: 'Reiniciar',
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(56, 56),
                    backgroundColor: rc.surface2,
                    foregroundColor: context.cs.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: timer.toggle,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: context.tt.titleMedium?.copyWith(fontSize: 16),
                  ),
                  icon: Icon(timer.running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(timer.running ? 'Pausar' : 'Iniciar'),
                ),
                if (isLinuxDesktop) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () {
                      if (!timer.running) timer.start();
                      MiniWindow.enter();
                    },
                    tooltip: 'Mini janela de foco',
                    iconSize: 22,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      backgroundColor: rc.surface2,
                      foregroundColor: context.cs.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: const Icon(Icons.picture_in_picture_alt_rounded),
                  ),
                ],
              ],
            ),
            SectionHeader('Suas 3 de hoje', count: '${selected.length}/${FocusTimer.maxSelected}'),
            if (selected.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Escolha até três tarefas para focar hoje.', style: TextStyle(color: rc.muted, fontSize: 13)),
              )
            else
              TaskList(
                selected,
                onOpen: onOpen,
                selectedId: selectedId,
                trailingBuilder: (t) => IconButton(
                  tooltip: 'Tirar do foco',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: rc.muted),
                  onPressed: () => timer.toggleSelected(t.id),
                ),
              ),
            if (candidates.isNotEmpty && selected.length < FocusTimer.maxSelected) ...[
              const SectionHeader('Escolher da lista de hoje'),
              const SizedBox(height: 6),
              for (final t in candidates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => timer.toggleSelected(t.id),
                    icon: Icon(Icons.add_rounded, size: 18, color: context.cs.primary),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cs.onSurface,
                      side: BorderSide(color: rc.line),
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
