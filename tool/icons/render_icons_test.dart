// Gera os PNGs do ícone a partir do mesmo desenho usado no app.
//
//   flutter test tool/icons/render_icons_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rumo/ui/brand/rumo_mark.dart';

Future<void> _render(String path, int px, RumoMarkPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera os ícones em assets/icon', () async {
    const dir = 'assets/icon';
    // Ícone completo, cantos arredondados (Linux, legado do Android).
    await _render('$dir/rumo-icon.png', 1024, const RumoMarkPainter());
    await _render('$dir/rumo-256.png', 256, const RumoMarkPainter());
    // Camadas do ícone adaptativo do Android (108 dp, área visível de 72 dp).
    await _render('$dir/android-background.png', 432, const RumoMarkPainter(rounded: false, glyph: false));
    await _render('$dir/android-foreground.png', 432, const RumoMarkPainter(background: false, designScale: 72 / 108));
    await _render(
      '$dir/android-monochrome.png',
      432,
      const RumoMarkPainter(background: false, designScale: 72 / 108, glyphColor: Color(0xFF000000)),
    );
    // Bandeja do sistema (fase do desktop).
    await _render('$dir/tray.png', 64, const RumoMarkPainter(background: false, designScale: 100 / 72));
    await _render(
      '$dir/tray-dark.png',
      64,
      const RumoMarkPainter(background: false, designScale: 100 / 72, glyphColor: Color(0xFF1B1F27)),
    );
  });
}
