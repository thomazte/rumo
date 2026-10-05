import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rumo/data/task_repository.dart';
import 'package:rumo/models/task.dart';
import 'package:rumo/state/task_store.dart';

void main() {
  final now = DateTime(2026, 10, 5, 13, 0);
  TaskStore makeStore([MemoryRepository? repo]) => TaskStore(repo ?? MemoryRepository(), clock: () => now);

  test('primeira abertura cria tarefas de boas-vindas e salva', () {
    fakeAsync((async) {
      final repo = MemoryRepository();
      final store = makeStore(repo);
      store.load();
      async.flushMicrotasks();
      expect(store.tasks, isNotEmpty);
      expect(store.dueToday(), isNotEmpty);
      expect(store.inbox(), hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(repo.saves, 1);
    });
  });

  test('separa atrasadas, hoje, próximos e inbox', () async {
    final store = makeStore(MemoryRepository(const RumoData(projects: defaultProjects, tasks: [])));
    await store.load();
    store.add(title: 'ontem', date: DateTime(2026, 10, 4));
    store.add(title: 'hoje 15h', date: DateTime(2026, 10, 5), minutes: 900);
    store.add(title: 'hoje sem hora', date: DateTime(2026, 10, 5), priority: Priority.high);
    store.add(title: 'quarta', date: DateTime(2026, 10, 7));
    store.add(title: 'ideia');
    store.add(title: 'do projeto', projectId: 'casa');

    expect(store.overdue().map((t) => t.title), ['ontem']);
    expect(store.dueToday().map((t) => t.title), ['hoje 15h', 'hoje sem hora']);
    expect(store.dueOn(DateTime(2026, 10, 7)).single.title, 'quarta');
    expect(store.inbox().single.title, 'ideia');
    expect(store.todayStats().total, 3);
    expect(store.nextTask()!.title, 'hoje 15h');
    store.dispose();
  });

  test('concluir conta no progresso e desfazer exclusão volta ao lugar', () async {
    final store = makeStore(MemoryRepository(const RumoData(projects: defaultProjects, tasks: [])));
    await store.load();
    final a = store.add(title: 'a', date: DateTime(2026, 10, 5));
    store.add(title: 'b', date: DateTime(2026, 10, 5));

    store.setDone(a.id, true);
    expect(store.todayStats().done, 1);
    expect(store.completedToday().single.id, a.id);

    final removed = store.delete(a.id)!;
    expect(store.byId(a.id), isNull);
    store.restore(removed.task, removed.index);
    expect(store.tasks.first.id, a.id);
    store.dispose();
  });

  test('arquivo JSON guarda e lê de volta', () async {
    final dir = await Directory.systemTemp.createTemp('rumo_test');
    addTearDown(() => dir.delete(recursive: true));
    final repo = JsonFileRepository(directory: () async => dir);
    final task = Task(
      id: 'x',
      title: 'com tudo',
      createdAt: now,
      date: DateTime(2026, 10, 9),
      minutes: 540,
      projectId: 'casa',
      priority: Priority.high,
      notes: 'nota',
      subtasks: const [Subtask(title: 's', done: true)],
    );
    await repo.save(const RumoData(projects: defaultProjects, tasks: []).copyWithTasks([task]));
    final back = (await repo.load())!.tasks.single;
    expect(back.toJson(), task.toJson());
  });
}

extension on RumoData {
  RumoData copyWithTasks(List<Task> tasks) => RumoData(projects: projects, tasks: tasks);
}
