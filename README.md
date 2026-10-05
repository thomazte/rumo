# Rumo

App de tarefas com captura rápida, modo foco e (em breve) widgets. Flutter, para Android e Linux.

## Rodar

```bash
flutter run -d linux
```

```bash
flutter run -d android
```

## Testes

```bash
flutter test
```

## Estrutura

| Pasta | O que tem |
|---|---|
| `lib/models` | Tarefa, subtarefa, projeto e prioridade |
| `lib/data` | Onde os dados ficam salvos (hoje: `rumo.json` na pasta de dados do app) |
| `lib/state` | `TaskStore` (tarefas e consultas) e `FocusTimer` (pomodoro) |
| `lib/util` | Datas em português e o parser da captura rápida |
| `lib/ui` | Tema, telas, folhas de captura e detalhe, ícone desenhado em código |
| `tool/icons` | Gera os PNGs do ícone a partir de `lib/ui/brand/rumo_mark.dart` |
| `tool/screens` | Renderiza as telas em `build/screens/` para revisão visual |
| `design/` | Protótipo HTML e as opções de ícone |

## Ícone

O desenho está em `lib/ui/brand/rumo_mark.dart`. Para regenerar depois de mudar:

```bash
flutter test tool/icons/render_icons_test.dart
```

```bash
dart run flutter_launcher_icons
```

No Linux (Wayland), o GNOME só mostra o ícone no dock se o atalho `.desktop` estiver instalado:

```bash
linux/packaging/install-dev.sh
```

## No computador (Linux)

- **Um app só:** abrir de novo traz a janela para a frente. Fechar a janela só esconde o Rumo; ele continua na bandeja. "Sair" no menu da bandeja encerra.
- **Atalho global:** `rumo --capture` abre a captura no Rumo que já está aberto. Na barra lateral, "Atalho global" cria o atalho `Ctrl+Alt+N` no GNOME.
- **Bandeja:** quantas tarefas faltam hoje, as próximas, nova tarefa, iniciar foco.
- **Mini janela de foco:** botão ao lado de Iniciar, na tela Foco. No Wayland, use "Sempre visível" no menu da barra de título para deixá-la por cima.

## Widgets do Android

Hoje, A seguir, Progresso e Adicionar, em `android/app/src/main/kotlin/com/thomazte/rumo/widget/` (Jetpack Glance). O app manda os dados por `lib/platform/home_widgets.dart`; concluir pelo widget roda em segundo plano.

## Atalhos dentro do app

- `Ctrl+N`: nova tarefa
- `Ctrl+1` a `Ctrl+5`: Hoje, Próximos, Inbox, Projetos, Foco
- `Esc`: fecha o painel da tarefa

## Próximas etapas

1. Sincronização entre celular e computador
2. Instalação no Linux (atalho no menu de aplicativos e ícone no dock)
