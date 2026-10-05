import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task.dart';

class RumoData {
  const RumoData({required this.projects, required this.tasks});

  final List<Project> projects;
  final List<Task> tasks;
}

/// Onde os dados ficam guardados. Hoje é um arquivo local; a sincronização
/// na nuvem entra depois como outra implementação desta interface.
abstract interface class TaskRepository {
  /// Nulo quando ainda não existe nada salvo (primeira abertura).
  Future<RumoData?> load();

  Future<void> save(RumoData data);
}

class JsonFileRepository implements TaskRepository {
  JsonFileRepository({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationSupportDirectory;

  static const _fileName = 'rumo.json';
  static const _version = 1;

  final Future<Directory> Function() _directory;

  Future<File> _file() async => File('${(await _directory()).path}/$_fileName');

  @override
  Future<RumoData?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return RumoData(
        projects: [
          for (final p in json['projects'] as List) Project.fromJson(p as Map<String, dynamic>),
        ],
        tasks: [
          for (final t in json['tasks'] as List) Task.fromJson(t as Map<String, dynamic>),
        ],
      );
    } on FormatException {
      // Guarda o arquivo ilegível ao lado em vez de sobrescrever os dados.
      await file.copy('${file.path}.ilegivel-${DateTime.now().millisecondsSinceEpoch}');
      return null;
    }
  }

  @override
  Future<void> save(RumoData data) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final json = jsonEncode({
      'version': _version,
      'projects': [for (final p in data.projects) p.toJson()],
      'tasks': [for (final t in data.tasks) t.toJson()],
    });
    // Escreve num temporário e renomeia, para nunca deixar o arquivo pela metade.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}

class MemoryRepository implements TaskRepository {
  MemoryRepository([this.data]);

  RumoData? data;
  int saves = 0;

  @override
  Future<RumoData?> load() async => data;

  @override
  Future<void> save(RumoData data) async {
    this.data = data;
    saves++;
  }
}
