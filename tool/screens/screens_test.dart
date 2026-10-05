// Renderiza as telas em PNG para revisão visual (build/screens/).
//
//   flutter test tool/screens/screens_test.dart
//
// Usa fontes do sistema no lugar das do Google, que não baixam em teste.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rumo/data/task_repository.dart';
import 'package:rumo/main.dart';
import 'package:rumo/models/task.dart';
import 'package:rumo/state/focus_timer.dart';
import 'package:rumo/state/task_store.dart';

const _flutterRoot = String.fromEnvironment('FLUTTER_ROOT', defaultValue: '/home/thom/snap/flutter/common/flutter');

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(seconds: 1));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await _loadFont('ShotSans', ['/usr/share/fonts/truetype/ubuntu/UbuntuSans[wdth,wght].ttf']);
    await _loadFont('MaterialIcons', ['$_flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  Future<TaskStore> sampleStore() async {
    final now = DateTime(2026, 10, 5, 9, 41);
    final store = TaskStore(MemoryRepository(), clock: () => now);
    await store.load(); // tarefas de boas-vindas
    final t = store.today;
    store.add(title: 'Enviar proposta para o cliente', date: t, minutes: 600, projectId: 'trabalho', priority: Priority.high);
    store.add(title: 'Pagar conta de luz', date: t.subtract(const Duration(days: 1)), projectId: 'casa', priority: Priority.high);
    store.add(title: 'Reunião de planejamento', date: t.add(const Duration(days: 1)), minutes: 570, projectId: 'trabalho');
    store.add(title: 'Marcar dentista', date: t.add(const Duration(days: 2)), projectId: 'saude', priority: Priority.low);
    return store;
  }

  for (final (name, size, dark) in [
    ('celular-claro', const Size(400, 860), false),
    ('celular-escuro', const Size(400, 860), true),
    ('desktop', const Size(1240, 800), false),
  ]) {
    testWidgets('tela $name', (tester) async {
      tester.view.physicalSize = size * 1.0;
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = await tester.runAsync(sampleStore);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('shot'),
        child: RumoApp(store: store!, focus: FocusTimer(), fontFamily: 'ShotSans'),
      ));
      await _shot(tester, '$name-hoje');

      if (name == 'desktop') {
        await tester.tap(find.text('Abra esta tarefa para ver subtarefas e notas'));
        await _shot(tester, '$name-detalhe');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'pagar aluguel sexta 9h #casa !alta');
        await _shot(tester, '$name-captura');
      } else {
        await tester.tap(find.text('Próximos').last);
        await _shot(tester, '$name-proximos');
        await tester.tap(find.text('Foco').last);
        await _shot(tester, '$name-foco');
        if (!dark) {
          await tester.tap(find.text('Hoje').last);
          await tester.pump();
          await tester.tap(find.text('Abra esta tarefa para ver subtarefas e notas'));
          await tester.pumpAndSettle();
          await _shot(tester, '$name-detalhe');
        }
      }
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }
}
