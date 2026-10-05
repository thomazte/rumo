# Linux

Testado no Ubuntu com GNOME no Wayland.

## Instância única

O runner (`linux/runner/my_application.cc`) registra o app no D-Bus como `com.thomazte.rumo`. Abrir de novo só traz a janela para a frente.

Fechar a janela esconde o Rumo, que continua na bandeja para o atalho e o timer seguirem funcionando. **Sair**, no menu da bandeja, encerra de verdade.

## Atalho global

No Wayland nenhum app captura teclas de outros programas. O caminho é o GNOME rodar um comando:

```bash
rumo --capture
```

Se já houver um Rumo aberto, o runner repassa o pedido pela ação D-Bus `capture`, traz a janela e avisa o Dart pelo canal `rumo/desktop`, que abre a captura.

Na barra lateral, **Atalho global** cria o atalho `Ctrl+Alt+N` nas configurações de teclado do GNOME (via `gsettings`). O comando aponta para o binário em `build/`; depois de instalar o app de outro jeito, crie o atalho de novo.

## Bandeja

`lib/platform/tray.dart`, com `tray_manager` (StatusNotifierItem por D-Bus). Mostra o número de tarefas que faltam hoje e um menu com:

- resumo do dia;
- até 6 tarefas de hoje e atrasadas, que abrem a tarefa;
- Nova tarefa, Iniciar foco, Abrir o Rumo e Sair.

No GNOME precisa da extensão de indicadores (já vem ativa no Ubuntu).

## Mini janela de foco

Botão ao lado de **Iniciar**, na tela Foco. Encolhe a janela para mostrar só o timer, a tarefa atual e os controles (`lib/ui/screens/mini_focus.dart`).

No Wayland o app não consegue ficar por cima das outras janelas sozinho. Clique com o botão direito na barra de título e escolha **Sempre visível**.

## Ícone no dock

No Wayland o GNOME ignora o ícone da janela e procura um `.desktop` com o mesmo id do app. Para instalar (só no seu usuário, sem `sudo`):

```bash
linux/packaging/install-dev.sh
```

Para remover, apague `~/.local/share/applications/com.thomazte.rumo.desktop` e `~/.local/share/icons/hicolor/256x256/apps/com.thomazte.rumo.png`.
