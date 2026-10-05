# Desenvolvimento

## Comandos

| Para | Comando |
|---|---|
| Rodar no Linux | `flutter run -d linux` |
| Rodar no celular | `flutter run -d android` |
| Analisar o código | `flutter analyze` |
| Testes | `flutter test` |
| Gerar o APK de teste | `flutter build apk --debug` |

## Celular

- Use sempre `flutter run`. **Não use `flutter install`**: ele desinstala o app antes e apaga as tarefas salvas no aparelho.
- Para ver os aparelhos conectados: `flutter devices`.

## Testes

| Arquivo | Cobre |
|---|---|
| `test/quick_parser_test.dart` | Captura rápida |
| `test/task_store_test.dart` | Consultas, concluir, desfazer e o arquivo JSON |
| `test/home_widgets_test.dart` | Dados enviados aos widgets e endereços `rumo://` |
| `test/desktop_test.dart` | Leitura da lista de atalhos do GNOME |

## Revisão visual

Renderiza as telas em `build/screens/` (celular claro e escuro, computador), sem abrir o app:

```bash
flutter test tool/screens/screens_test.dart
```

Usa as fontes do sistema no lugar das do Google, que não baixam em teste. Nas imagens, a borda preta em volta do botão + é um efeito do modo de teste (sombras desligadas), não aparece no app.

## Fontes

Figtree, Bricolage Grotesque e JetBrains Mono vêm do pacote `google_fonts` e são baixadas na primeira abertura. Antes de publicar na loja, embutir os arquivos em `google_fonts/` para funcionar sem internet.
