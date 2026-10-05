import 'package:flutter_test/flutter_test.dart';
import 'package:rumo/platform/desktop.dart';

void main() {
  test('lê a lista de atalhos do gsettings', () {
    expect(parseGsettingsList('@as []'), isEmpty);
    expect(parseGsettingsList("['/a/custom0/', '/a/rumo-capture/']\n"), ['/a/custom0/', '/a/rumo-capture/']);
  });
}
