import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../platform/desktop.dart';
import '../../state/focus_timer.dart';
import '../../state/scope.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A janela encolhida do modo foco: timer, tarefa atual e controles.
class MiniFocusView extends StatelessWidget {
  const MiniFocusView({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.focusTimer;
    final store = context.store;
    final rc = context.rc;

    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([timer, store]),
        builder: (context, _) {
          final pause = timer.mode == FocusMode.pause;
          final current = [for (final id in timer.selected) store.byId(id)]
              .whereType<Task>()
              .where((t) => !t.done)
              .firstOrNull;
          final label = pause ? 'Pausa' : current?.title ?? 'Sem tarefa escolhida';

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                ProgressRing(
                  value: timer.progress,
                  size: 112,
                  stroke: 8,
                  color: pause ? rc.low : null,
                  child: Text(formatClock(timer.remaining), style: monoStyle(context, size: 24, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (pause ? 'Pausa · 5 min' : 'Foco · 25 min').toUpperCase(),
                        style: context.tt.labelSmall?.copyWith(color: rc.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (current != null && !pause) ...[
                            IconButton.outlined(
                              tooltip: 'Concluir tarefa',
                              onPressed: () => store.setDone(current.id, true),
                              icon: const Icon(Icons.check_rounded),
                            ),
                            const SizedBox(width: 6),
                          ],
                          IconButton.filled(
                            tooltip: timer.running ? 'Pausar' : 'Iniciar',
                            onPressed: timer.toggle,
                            icon: Icon(timer.running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Voltar ao tamanho normal',
                            onPressed: MiniWindow.exit,
                            icon: Icon(Icons.open_in_full_rounded, color: rc.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
