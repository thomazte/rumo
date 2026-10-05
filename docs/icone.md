# Ícone

O anel de progresso com um check, branco sobre um gradiente azul. Desenhado em código em `lib/ui/brand/rumo_mark.dart`, numa caixa de 100×100 (a mesma geometria dos SVGs em `design/icone/`). O app usa o mesmo desenho na barra lateral.

## Gerar os arquivos

Depois de mudar o desenho ou as cores:

```bash
flutter test tool/icons/render_icons_test.dart
```

```bash
dart run flutter_launcher_icons
```

O primeiro gera os PNGs em `assets/icon/`; o segundo aplica no Android.

| Arquivo | Uso |
|---|---|
| `rumo-icon.png` (1024) | Ícone do Android em versões antigas |
| `rumo-256.png` | Janela e dock do Linux, logo dos widgets |
| `android-foreground.png`, `android-background.png` | Ícone adaptativo do Android (desenho na área segura de 72/108 dp) |
| `android-monochrome.png` | Ícone temático do Android 13+ |
| `tray.png`, `tray-dark.png` | Bandeja do Linux (barra escura e clara) |

O logo dos widgets é uma cópia em `android/app/src/main/res/drawable-nodpi/widget_logo.png`; atualize junto.
