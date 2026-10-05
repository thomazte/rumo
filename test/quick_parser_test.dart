import 'package:flutter_test/flutter_test.dart';
import 'package:rumo/models/task.dart';
import 'package:rumo/util/quick_parser.dart';

void main() {
  // Segunda-feira, 5 de outubro de 2026.
  final today = DateTime(2026, 10, 5);
  ParsedTask parse(String s) => parseQuickEntry(s, projects: defaultProjects, today: today);

  test('separa data, hora, projeto e prioridade', () {
    final p = parse('pagar aluguel sexta 9h #casa !alta');
    expect(p.title, 'pagar aluguel');
    expect(p.date, DateTime(2026, 10, 9));
    expect(p.minutes, 9 * 60);
    expect(p.projectId, 'casa');
    expect(p.priority, Priority.high);
  });

  test('aceita acentos, "às" e minutos', () {
    final p = parse('Reunião amanhã às 14:30 #saúde');
    expect(p.title, 'Reunião');
    expect(p.date, DateTime(2026, 10, 6));
    expect(p.minutes, 14 * 60 + 30);
    expect(p.projectId, 'saude');
  });

  test('dia da semana igual a hoje cai hoje; "próxima" funciona', () {
    expect(parse('treino segunda').date, today);
    expect(parse('dentista na próxima quarta-feira').date, DateTime(2026, 10, 7));
    expect(parse('dentista na próxima quarta-feira').title, 'dentista');
  });

  test('data numérica vai para o ano seguinte se já passou', () {
    expect(parse('renovar cnh 12/10').date, DateTime(2026, 10, 12));
    expect(parse('declarar ir 30/04').date, DateTime(2027, 4, 30));
    expect(parse('data impossível 31/02').date, isNull);
  });

  test('projeto desconhecido e palavras comuns ficam no título', () {
    final p = parse('ter que ligar #mercado 3h de estudo');
    expect(p.projectId, isNull);
    expect(p.title, 'ter que ligar #mercado de estudo');
    expect(p.minutes, 3 * 60);
  });

  test('prefixo do projeto e prioridade numérica', () {
    final p = parse('relatório #trab !2');
    expect(p.projectId, 'trabalho');
    expect(p.priority, Priority.medium);
    expect(p.date, isNull);
  });
}
