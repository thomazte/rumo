import 'package:flutter/widgets.dart';

import 'focus_timer.dart';
import 'task_store.dart';

/// Disponibiliza o store e o timer para toda a árvore, inclusive diálogos.
class RumoScope extends InheritedWidget {
  const RumoScope({super.key, required this.store, required this.focus, required super.child});

  final TaskStore store;
  final FocusTimer focus;

  static RumoScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<RumoScope>();
    assert(scope != null, 'RumoScope não encontrado acima deste widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(RumoScope oldWidget) => store != oldWidget.store || focus != oldWidget.focus;
}

extension RumoScopeContext on BuildContext {
  TaskStore get store => RumoScope.of(this).store;
  FocusTimer get focusTimer => RumoScope.of(this).focus;
}
