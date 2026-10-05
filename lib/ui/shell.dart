import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/desktop.dart';
import '../platform/home_widgets.dart';
import '../state/scope.dart';
import 'brand/rumo_mark.dart';
import 'screens/focus_screen.dart';
import 'screens/lists.dart';
import 'sheets/quick_capture.dart';
import 'sheets/shortcut_dialog.dart';
import 'sheets/task_detail.dart';
import 'theme.dart';
import 'widgets/common.dart';

enum RumoTab {
  today('Hoje', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
  upcoming('Próximos', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
  inbox('Inbox', Icons.inbox_outlined, Icons.inbox_rounded),
  projects('Projetos', Icons.grid_view_outlined, Icons.grid_view_rounded),
  focus('Foco', Icons.timer_outlined, Icons.timer_rounded);

  const RumoTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.links});

  final Stream<AppLink>? links;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  RumoTab _tab = RumoTab.today;
  String? _openProjectId;

  /// Tarefa aberta no painel lateral (só em tela larga).
  String? _selectedTaskId;

  StreamSubscription<AppLink>? _links;

  @override
  void initState() {
    super.initState();
    _links = widget.links?.listen((link) {
      // Espera o primeiro quadro: na abertura o app ainda está montando.
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (mounted) _openLink(link);
        })
        // Com a janela parada nenhum quadro viria por conta própria.
        ..scheduleFrame();
    });
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  void _openLink(AppLink link) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    switch (link) {
      case CaptureLink():
        _select(RumoTab.today);
        _capture();
      case TaskLink(:final id):
        _select(RumoTab.today);
        if (context.store.byId(id) != null) _openTask(id);
      case OpenLink(:final tab):
        _select(tab == 'focus' ? RumoTab.focus : RumoTab.today);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.focusTimer.onMessage = (m) {
      if (mounted) showRumoSnack(ScaffoldMessenger.of(context), m);
    };
  }

  bool get _wide => MediaQuery.sizeOf(context).width >= wideBreakpoint;

  void _select(RumoTab tab, {String? projectId}) => setState(() {
        _tab = tab;
        _openProjectId = projectId;
      });

  void _openTask(String id) {
    if (_wide) {
      setState(() => _selectedTaskId = id);
    } else {
      showTaskDetailSheet(context, id);
    }
  }

  Future<void> _capture() async {
    final store = context.store;
    final task = await showQuickCapture(
      context,
      defaultDate: _tab == RumoTab.today ? store.today : null,
      defaultProjectId: _tab == RumoTab.projects ? _openProjectId : null,
    );
    if (task == null || !mounted) return;
    showRumoSnack(
      ScaffoldMessenger.of(context),
      'Adicionada em ${store.destinationOf(date: task.date, projectId: task.projectId)}',
      onUndo: () => store.delete(task.id),
    );
  }

  Widget _screen() {
    final selected = _wide ? _selectedTaskId : null;
    return switch (_tab) {
      RumoTab.today => TodayScreen(onOpen: _openTask, selectedId: selected),
      RumoTab.upcoming => UpcomingScreen(onOpen: _openTask, selectedId: selected),
      RumoTab.inbox => InboxScreen(onOpen: _openTask, selectedId: selected),
      RumoTab.projects => _openProjectId == null
          ? ProjectsScreen(onOpenProject: (id) => setState(() => _openProjectId = id))
          : ProjectScreen(
              projectId: _openProjectId!,
              onBack: () => setState(() => _openProjectId = null),
              onOpen: _openTask,
              selectedId: selected,
            ),
      RumoTab.focus => FocusScreen(onOpen: _openTask, selectedId: selected),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _capture,
        for (final tab in RumoTab.values)
          SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + tab.index), control: true): () => _select(tab),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedTaskId != null) setState(() => _selectedTaskId = null);
        },
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            if (_selectedTaskId != null && store.byId(_selectedTaskId!) == null) _selectedTaskId = null;
            return _wide ? _buildWide(context) : _buildNarrow(context);
          },
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final inboxCount = context.store.inbox().length;
    return Scaffold(
      body: SafeArea(bottom: false, child: KeyedSubtree(key: ValueKey((_tab, _openProjectId)), child: _screen())),
      floatingActionButton: FloatingActionButton(
        onPressed: _capture,
        tooltip: 'Nova tarefa',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) => _select(RumoTab.values[i]),
        destinations: [
          for (final tab in RumoTab.values)
            NavigationDestination(
              icon: tab == RumoTab.inbox
                  ? Badge(isLabelVisible: inboxCount > 0, label: Text('$inboxCount'), child: Icon(tab.icon))
                  : Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              tab: _tab,
              openProjectId: _openProjectId,
              onSelect: _select,
              onCapture: _capture,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: KeyedSubtree(key: ValueKey((_tab, _openProjectId)), child: _screen()),
                  ),
                ),
              ),
            ),
            if (_selectedTaskId != null) ...[
              const VerticalDivider(width: 1),
              SizedBox(
                width: 400,
                child: TaskDetailView(
                  key: const ValueKey('detail-pane'),
                  taskId: _selectedTaskId!,
                  onClose: () => setState(() => _selectedTaskId = null),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.tab, required this.openProjectId, required this.onSelect, required this.onCapture});

  final RumoTab tab;
  final String? openProjectId;
  final void Function(RumoTab tab, {String? projectId}) onSelect;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final rc = context.rc;
    final counts = {
      RumoTab.today: store.overdue().length + store.dueToday().length,
      RumoTab.inbox: store.inbox().length,
    };

    return Container(
      width: 260,
      color: rc.surface2,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const RumoLogo(size: 32),
                const SizedBox(width: 10),
                Text('Rumo', style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onCapture,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Nova tarefa')),
                Text('Ctrl+N', style: monoStyle(context, size: 11, color: context.cs.onPrimary.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final t in RumoTab.values)
            _SideItem(
              icon: tab == t ? t.selectedIcon : t.icon,
              label: t.label,
              count: counts[t],
              selected: tab == t && (t != RumoTab.projects || openProjectId == null),
              onTap: () => onSelect(t),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 6),
            child: Text('PROJETOS', style: context.tt.labelSmall?.copyWith(color: rc.muted)),
          ),
          for (final p in store.projects)
            _SideItem(
              leading: ProjectDot(rc.project(p), size: 10),
              label: p.name,
              count: store.ofProject(p.id).where((t) => !t.done).length,
              selected: tab == RumoTab.projects && openProjectId == p.id,
              onTap: () => onSelect(RumoTab.projects, projectId: p.id),
            ),
          if (isLinuxDesktop) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 8),
            _SideItem(
              icon: Icons.keyboard_command_key_rounded,
              label: 'Atalho global',
              selected: false,
              onTap: () => showShortcutDialog(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.label, required this.selected, required this.onTap, this.icon, this.leading, this.count});

  final IconData? icon;
  final Widget? leading;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.cs.primary : context.cs.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? context.cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Center(child: leading ?? Icon(icon, size: 20, color: selected ? color : context.rc.muted)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
                  ),
                  if (count != null && count! > 0)
                    Text('$count', style: monoStyle(context, size: 12, color: context.rc.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
