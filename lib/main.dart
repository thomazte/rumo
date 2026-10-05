import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';

import 'data/task_repository.dart';
import 'platform/desktop.dart';
import 'platform/home_widgets.dart';
import 'platform/tray.dart';
import 'state/focus_timer.dart';
import 'state/scope.dart';
import 'state/task_store.dart';
import 'ui/screens/mini_focus.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

/// Precisa continuar referenciada: se for coletada, o ícone some da bandeja.
RumoTray? _tray;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await MiniWindow.init();
  final store = TaskStore(JsonFileRepository());
  await store.load();
  if (homeWidgetsSupported) {
    await HomeWidget.registerInteractivityCallback(homeWidgetInteraction);
    HomeWidgetSync(store).attach();
  }
  final focus = FocusTimer();
  if (isLinuxDesktop) {
    _tray = RumoTray(store: store, focus: focus);
    await _tray!.attach();
  }
  runApp(RumoApp(
    store: store,
    focus: focus,
    links: mergeLinks([widgetLinks(), desktopLinks(args)]),
  ));
}

/// Junta os pedidos dos widgets do Android e do atalho do computador.
Stream<AppLink> mergeLinks(List<Stream<AppLink>> sources) {
  final controller = StreamController<AppLink>();
  for (final s in sources) {
    s.listen(controller.add);
  }
  return controller.stream;
}

class RumoApp extends StatefulWidget {
  const RumoApp({super.key, required this.store, required this.focus, this.links, this.fontFamily});

  final TaskStore store;
  final FocusTimer focus;

  /// Pedidos externos: toques em widgets, `rumo --capture`.
  final Stream<AppLink>? links;

  /// Só para testes: usa uma fonte local em vez das do Google.
  final String? fontFamily;

  @override
  State<RumoApp> createState() => _RumoAppState();
}

class _RumoAppState extends State<RumoApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Garante que nada fica sem salvar ao minimizar ou fechar.
    _lifecycle = AppLifecycleListener(
      onPause: widget.store.flush,
      // O widget pode ter concluído tarefas enquanto o app estava fechado.
      onResume: homeWidgetsSupported ? widget.store.reload : null,
      onHide: widget.store.flush,
      onExitRequested: () async {
        await widget.store.flush();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RumoScope(
      store: widget.store,
      focus: widget.focus,
      child: MaterialApp(
        title: 'Rumo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light, fontFamily: widget.fontFamily),
        darkTheme: buildTheme(Brightness.dark, fontFamily: widget.fontFamily),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ValueListenableBuilder(
          valueListenable: MiniWindow.active,
          builder: (context, mini, _) => Stack(
            children: [
              Offstage(offstage: mini, child: HomeShell(links: widget.links)),
              if (mini) const MiniFocusView(),
            ],
          ),
        ),
      ),
    );
  }
}
