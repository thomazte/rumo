import 'dart:async';

import 'package:flutter/foundation.dart';

enum FocusMode { focus, pause }

/// Pomodoro: 25 minutos de foco, 5 de pausa, e até 3 tarefas escolhidas.
class FocusTimer extends ChangeNotifier {
  static const focusLength = Duration(minutes: 25);
  static const pauseLength = Duration(minutes: 5);
  static const maxSelected = 3;

  FocusMode _mode = FocusMode.focus;
  Duration _remaining = focusLength;
  bool _running = false;
  int _cycles = 0;
  final List<String> _selected = [];
  Timer? _ticker;
  DateTime? _endsAt;

  /// Avisos para mostrar ao usuário (fim de ciclo, fim de pausa).
  void Function(String message)? onMessage;

  FocusMode get mode => _mode;
  Duration get remaining => _remaining;
  bool get running => _running;
  int get cycles => _cycles;
  List<String> get selected => List.unmodifiable(_selected);
  Duration get total => _mode == FocusMode.focus ? focusLength : pauseLength;
  double get progress => _remaining.inMilliseconds / total.inMilliseconds;

  void start() {
    if (_running) return;
    _running = true;
    _endsAt = DateTime.now().add(_remaining);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    _stop();
    notifyListeners();
  }

  void toggle() => _running ? pause() : start();

  void reset() {
    _stop();
    _remaining = total;
    notifyListeners();
  }

  void setMode(FocusMode mode) {
    _stop();
    _mode = mode;
    _remaining = total;
    notifyListeners();
  }

  bool isSelected(String id) => _selected.contains(id);

  void toggleSelected(String id) {
    if (!_selected.remove(id)) {
      if (_selected.length >= maxSelected) return;
      _selected.add(id);
    }
    notifyListeners();
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _running = false;
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now());
    if (left <= Duration.zero) {
      _stop();
      if (_mode == FocusMode.focus) {
        _cycles++;
        _mode = FocusMode.pause;
        onMessage?.call('Ciclo concluído. Hora da pausa.');
      } else {
        _mode = FocusMode.focus;
        onMessage?.call('Pausa encerrada. Bora pro próximo.');
      }
      _remaining = total;
      notifyListeners();
      return;
    }
    final seconds = Duration(seconds: (left.inMilliseconds / 1000).ceil());
    if (seconds != _remaining) {
      _remaining = seconds;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
