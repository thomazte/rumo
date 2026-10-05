# Widgets do Android

Feitos com Jetpack Glance, em `android/app/src/main/kotlin/com/thomazte/rumo/widget/`. O pacote `home_widget` faz a ponte com o Flutter.

| Widget | Tamanho | O que faz |
|---|---|---|
| Hoje | 4×2, redimensionável | Lista do dia. O círculo conclui, o título abre a tarefa, o + abre a captura |
| A seguir | 2×2 | Próxima tarefa com horário hoje; senão a mais urgente |
| Progresso | 2×2 | Anel com quanto do dia foi feito |
| Adicionar tarefa | 4×1 | Abre a captura rápida |

## Como os dados chegam

1. `HomeWidgetSync` (`lib/platform/home_widgets.dart`) escuta o `TaskStore` e, 600 ms depois de cada mudança, grava um JSON na chave `rumo_widget`.
2. O JSON leva as tarefas abertas até 14 dias à frente e as datas de conclusão de hoje. O widget calcula "hoje" na hora de desenhar, então vira o dia sozinho (a cada 30 minutos, ou quando o app atualiza).
3. `WidgetData.kt` lê esse JSON; `Widgets.kt` desenha.

## Concluir pelo widget

1. `ToggleTaskAction` guarda o id em `rumo_widget_pending`, que esconde a tarefa na hora.
2. Dispara `rumo://toggle?id=…` em segundo plano. O Flutter roda `homeWidgetInteraction`, marca a tarefa como feita no `rumo.json` e atualiza os widgets.
3. Ao voltar para a frente, o app relê o arquivo. Com o app aberto, ele é a fonte da verdade e limpa os ids pendentes.

## Endereços que abrem o app

| Endereço | Efeito |
|---|---|
| `rumo://capture` | Abre a captura rápida |
| `rumo://task?id=…` | Abre a tarefa |
| `rumo://open?tab=today` / `focus` | Abre a tela |

Tratados em `HomeShell._openLink` (`lib/ui/shell.dart`), junto com os pedidos que chegam do Linux.

## Cores

`RumoColors` em `WidgetData.kt` repete a paleta de `lib/ui/theme.dart`, em claro e escuro. Mudou uma, mude a outra.
