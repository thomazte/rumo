import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

import '../state/focus_timer.dart';
import '../state/task_store.dart';
import '../util/dates.dart';
import 'desktop.dart';
import 'home_widgets.dart';

/// Ícone do Rumo na barra do sistema, com o resumo do dia e atalhos.
///
/// Fechar a janela só esconde o Rumo: ele continua na bandeja para o atalho
/// global e o timer seguirem funcionando. "Sair" no menu encerra de verdade.
class RumoTray with WindowListener {
  RumoTray({required this.store, required this.focus});

  final TaskStore store;
  final FocusTimer focus;

  tray.TrayIcon? _icon;
  // Mantém vivos os objetos nativos do menu atual.
  final List<Object> _menuObjects = [];
  Timer? _debounce;

  static const _maxTasks = 6;

  Future<void> attach() async {
    if (!isLinuxDesktop) return;
    try {
      if (!tray.TrayManager.instance.isSupported()) return;
      final icon = tray.TrayIcon.create();
      if (icon == null) return;
      icon.icon = tray.ImageAsset.fromAsset('assets/icon/tray.png');
      icon.setVisible(true);
      _icon = icon;
    } catch (e) {
      debugPrint('Bandeja indisponível: $e');
      return;
    }
    store.addListener(_schedule);
    _rebuild();

    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _rebuild);
  }

  Future<void> _show(AppLink? link) async {
    await windowManager.show();
    await windowManager.focus();
    if (link != null) sendDesktopLink(link);
  }

  Future<void> _quit() async {
    await store.flush();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  void _rebuild() {
    final icon = _icon;
    if (icon == null) return;
    final stats = store.todayStats();
    final pending = [...store.overdue(), ...store.dueToday()];

    final menu = tray.Menu.create();
    if (menu == null) return;
    final objects = <Object>[menu];

    void item(String label, {VoidCallback? onClick, bool enabled = true}) {
      final it = tray.MenuItem.createWithLabelAndType(label, tray.MenuItemType.normal);
      if (it == null) return;
      it.isEnabled = enabled;
      if (onClick != null) {
        it.addListener((event) {
          if (event is tray.MenuItemClickedEvent) onClick();
        });
      }
      menu.addItem(it);
      objects.add(it);
    }

    item(
      stats.left == 0
          ? 'Hoje: tudo feito (${stats.done}/${stats.total})'
          : 'Hoje: ${stats.left} ${stats.left == 1 ? 'restante' : 'restantes'} · ${stats.done}/${stats.total}',
      enabled: false,
    );
    menu.addSeparator();
    for (final t in pending.take(_maxTasks)) {
      final late = t.date!.isBefore(store.today);
      final prefix = late ? 'Atrasada · ' : (t.minutes != null ? '${formatMinutes(t.minutes!)} · ' : '');
      item('$prefix${t.title}', onClick: () => _show(TaskLink(t.id)));
    }
    if (pending.length > _maxTasks) {
      item('+${pending.length - _maxTasks} no app', onClick: () => _show(const OpenLink('today')));
    }
    if (pending.isEmpty) item('Nada pendente para hoje', enabled: false);
    menu.addSeparator();
    item('Nova tarefa  ($gnomeShortcutLabel)', onClick: () => _show(const CaptureLink()));
    item(focus.running ? 'Abrir o foco' : 'Iniciar foco', onClick: () {
      if (!focus.running) focus.start();
      _show(const OpenLink('focus'));
    });
    item('Abrir o Rumo', onClick: () => _show(null));
    menu.addSeparator();
    item('Sair', onClick: _quit);

    icon.setContextMenu(menu);
    icon.setTitle(stats.left == 0 ? null : '${stats.left}');
    icon.setTooltip('Rumo · ${stats.left} para hoje');
    _menuObjects
      ..clear()
      ..addAll(objects);
  }

  // Fechar a janela esconde em vez de encerrar.
  @override
  void onWindowClose() async {
    await store.flush();
    await windowManager.hide();
  }
}
