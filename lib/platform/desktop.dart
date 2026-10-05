import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'home_widgets.dart';

bool get isLinuxDesktop => !kIsWeb && Platform.isLinux;

/// Pedidos que chegam de fora do app no computador.
///
/// `rumo --capture` (por exemplo, por um atalho do GNOME) abre a captura no
/// Rumo que já está aberto: o runner em linux/runner/my_application.cc repassa
/// o pedido por D-Bus e avisa aqui pelo canal "rumo/desktop".
final _desktopLinks = StreamController<AppLink>();

/// Para a bandeja e outros pontos do computador pedirem algo à tela principal.
void sendDesktopLink(AppLink link) => _desktopLinks.add(link);

Stream<AppLink> desktopLinks(List<String> args) {
  if (!isLinuxDesktop) return const Stream.empty();
  const MethodChannel('rumo/desktop').setMethodCallHandler((call) async {
    if (call.method == 'capture') sendDesktopLink(const CaptureLink());
  });
  if (args.contains('--capture')) sendDesktopLink(const CaptureLink());
  return _desktopLinks.stream;
}

// ---------- Mini janela de foco ----------

/// Encolhe a janela para mostrar só o timer, por cima das outras quando o
/// sistema permite (no Wayland do GNOME: clique direito na barra › Sempre visível).
class MiniWindow {
  MiniWindow._();

  static final active = ValueNotifier(false);
  static Rect? _previous;

  static const _miniSize = Size(340, 190);

  static Future<void> init() async {
    if (!isLinuxDesktop) return;
    await windowManager.ensureInitialized();
  }

  static Future<void> enter() async {
    if (!isLinuxDesktop || active.value) return;
    _previous = await windowManager.getBounds();
    await windowManager.setMinimumSize(_miniSize);
    await windowManager.setSize(_miniSize);
    await windowManager.setAlwaysOnTop(true);
    active.value = true;
  }

  static Future<void> exit() async {
    if (!isLinuxDesktop || !active.value) return;
    active.value = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setMinimumSize(const Size(380, 560));
    if (_previous != null) await windowManager.setBounds(_previous!);
  }
}

// ---------- Atalho global no GNOME ----------

const _keysSchema = 'org.gnome.settings-daemon.plugins.media-keys';
const _bindingSchema = '$_keysSchema.custom-keybinding';
const _bindingPath = '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rumo-capture/';

/// Ctrl+Alt+N no formato do GNOME.
const gnomeShortcut = '<Control><Alt>n';
const gnomeShortcutLabel = 'Ctrl+Alt+N';

String get captureCommand => '${Platform.resolvedExecutable} --capture';

@visibleForTesting
List<String> parseGsettingsList(String raw) {
  final s = raw.trim().replaceFirst('@as', '').trim();
  return RegExp(r"'([^']*)'").allMatches(s).map((m) => m[1]!).toList();
}

/// Cria (ou atualiza) um atalho personalizado do GNOME que roda `rumo --capture`.
/// Só roda quando a pessoa toca no botão na tela do app.
Future<String?> installGnomeShortcut() async {
  Future<ProcessResult> gs(List<String> args) => Process.run('gsettings', args);
  try {
    final current = await gs(['get', _keysSchema, 'custom-keybindings']);
    if (current.exitCode != 0) return 'O gsettings não respondeu. Este computador usa GNOME?';
    final paths = parseGsettingsList(current.stdout as String);
    for (final (key, value) in [
      ('name', 'Rumo: nova tarefa'),
      ('command', captureCommand),
      ('binding', gnomeShortcut),
    ]) {
      final r = await gs(['set', '$_bindingSchema:$_bindingPath', key, value]);
      if (r.exitCode != 0) return 'Não foi possível salvar o atalho: ${r.stderr}';
    }
    if (!paths.contains(_bindingPath)) {
      final list = [...paths, _bindingPath].map((p) => "'$p'").join(', ');
      final r = await gs(['set', _keysSchema, 'custom-keybindings', '[$list]']);
      if (r.exitCode != 0) return 'Não foi possível registrar o atalho: ${r.stderr}';
    }
    return null;
  } on ProcessException {
    return 'O gsettings não está disponível neste computador.';
  }
}
