import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../data/task_repository.dart';
import '../state/task_store.dart';
import '../util/dates.dart';

// Mesmas chaves e classes de android/app/src/main/kotlin/com/thomazte/rumo/widget/.
const _dataKey = 'rumo_widget';
const _pendingKey = 'rumo_widget_pending';
const _receivers = [
  'com.thomazte.rumo.widget.TodayWidgetReceiver',
  'com.thomazte.rumo.widget.NextWidgetReceiver',
  'com.thomazte.rumo.widget.ProgressWidgetReceiver',
  'com.thomazte.rumo.widget.AddWidgetReceiver',
];

bool get homeWidgetsSupported => !kIsWeb && Platform.isAndroid;

/// O que os widgets precisam, em JSON compacto. "Hoje" é calculado no widget,
/// por isso vão também as tarefas dos próximos dias.
@visibleForTesting
String widgetSnapshot(TaskStore store) {
  final today = store.today;
  final horizon = addDays(today, 14);
  final open = TaskStore.sorted(store.tasks.where((t) => !t.done && t.date != null && !t.date!.isAfter(horizon)));
  final done = [
    for (final t in store.tasks)
      if (t.done && t.doneAt != null && !t.doneAt!.isBefore(today)) isoDate(t.doneAt!),
  ];
  return jsonEncode({
    'tasks': [
      for (final t in open.take(60))
        {
          'id': t.id,
          't': t.title,
          'd': isoDate(t.date!),
          'm': ?t.minutes,
          'p': t.priority.index,
          if (store.project(t.projectId) case final p?) ...{'pn': p.name, 'pc': p.color},
        },
    ],
    'done': done,
  });
}

/// Mantém os widgets em dia com o que acontece no app.
class HomeWidgetSync {
  HomeWidgetSync(this.store);

  final TaskStore store;
  Timer? _debounce;

  void attach() {
    store.addListener(_schedule);
    _push();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _push);
  }

  // Com o app aberto ele é a fonte da verdade: limpa o que o widget escondeu.
  Future<void> _push() => pushHomeWidgets(store, clearPending: true);
}

Future<void> pushHomeWidgets(TaskStore store, {bool clearPending = false, String? processedId}) async {
  try {
    await HomeWidget.saveWidgetData<String>(_dataKey, widgetSnapshot(store));
    if (clearPending) {
      await HomeWidget.saveWidgetData<String>(_pendingKey, null);
    } else if (processedId != null) {
      final pending = (await HomeWidget.getWidgetData<String>(_pendingKey))?.split(',') ?? const [];
      final rest = pending.where((id) => id.isNotEmpty && id != processedId).join(',');
      await HomeWidget.saveWidgetData<String>(_pendingKey, rest.isEmpty ? null : rest);
    }
    for (final r in _receivers) {
      await HomeWidget.updateWidget(qualifiedAndroidName: r);
    }
  } catch (e) {
    debugPrint('Não foi possível atualizar os widgets: $e');
  }
}

/// Roda em segundo plano quando o círculo de um widget é tocado.
@pragma('vm:entry-point')
Future<void> homeWidgetInteraction(Uri? uri) async {
  if (uri?.host != 'toggle') return;
  final id = uri!.queryParameters['id'];
  if (id == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  final store = TaskStore(JsonFileRepository());
  await store.load();
  store.setDone(id, true);
  await store.flush();
  await pushHomeWidgets(store, processedId: id);
  store.dispose();
}

/// Endereços que os widgets abrem: rumo://capture, rumo://task?id=…, rumo://open?tab=…
sealed class AppLink {
  const AppLink();

  static AppLink? parse(Uri? uri) {
    if (uri == null || uri.scheme != 'rumo') return null;
    return switch (uri.host) {
      'capture' => const CaptureLink(),
      'task' when uri.queryParameters['id'] != null => TaskLink(uri.queryParameters['id']!),
      'open' => OpenLink(uri.queryParameters['tab'] ?? 'today'),
      _ => null,
    };
  }
}

class CaptureLink extends AppLink {
  const CaptureLink();
}

class TaskLink extends AppLink {
  const TaskLink(this.id);
  final String id;
}

class OpenLink extends AppLink {
  const OpenLink(this.tab);
  final String tab;
}

/// Toques nos widgets que abrem o app (na abertura e com ele já aberto).
Stream<AppLink> widgetLinks() async* {
  if (!homeWidgetsSupported) return;
  final initial = AppLink.parse(await HomeWidget.initiallyLaunchedFromHomeWidget());
  if (initial != null) yield initial;
  await for (final uri in HomeWidget.widgetClicked) {
    final link = AppLink.parse(uri);
    if (link != null) yield link;
  }
}
