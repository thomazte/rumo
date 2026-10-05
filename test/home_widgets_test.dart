import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rumo/data/task_repository.dart';
import 'package:rumo/models/task.dart';
import 'package:rumo/platform/home_widgets.dart';
import 'package:rumo/state/task_store.dart';

void main() {
  test('snapshot leva pendentes com data e as concluídas de hoje', () async {
    final now = DateTime(2026, 10, 5, 13);
    final store = TaskStore(MemoryRepository(const RumoData(projects: defaultProjects, tasks: [])), clock: () => now);
    await store.load();
    final a = store.add(title: 'hoje', date: now, minutes: 600, projectId: 'casa', priority: Priority.high);
    store.add(title: 'sem data');
    store.add(title: 'longe demais', date: DateTime(2026, 12, 1));
    final b = store.add(title: 'feita', date: now);
    store.setDone(b.id, true);

    final json = jsonDecode(widgetSnapshot(store)) as Map<String, dynamic>;
    final tasks = json['tasks'] as List;
    expect(tasks, hasLength(1));
    expect(tasks.single, {'id': a.id, 't': 'hoje', 'd': '2026-10-05', 'm': 600, 'p': 3, 'pn': 'Casa', 'pc': 'orange'});
    expect(json['done'], ['2026-10-05']);
    store.dispose();
  });

  test('entende os endereços dos widgets', () {
    expect(AppLink.parse(Uri.parse('rumo://capture')), isA<CaptureLink>());
    expect((AppLink.parse(Uri.parse('rumo://task?id=abc')) as TaskLink).id, 'abc');
    expect((AppLink.parse(Uri.parse('rumo://open?tab=focus')) as OpenLink).tab, 'focus');
    expect(AppLink.parse(Uri.parse('https://exemplo.com')), isNull);
  });
}
