# Arquitetura

## Pastas

| Pasta | O que tem |
|---|---|
| `lib/models` | Tarefa, subtarefa, projeto e prioridade |
| `lib/data` | `TaskRepository`: onde os dados ficam salvos |
| `lib/state` | `TaskStore` (tarefas e consultas), `FocusTimer` (pomodoro) e `RumoScope` |
| `lib/util` | Datas em português e o parser da captura rápida |
| `lib/platform` | Integrações: widgets do Android, atalho/mini janela e bandeja do Linux |
| `lib/ui` | Tema, telas, folhas de captura e detalhe, ícone desenhado em código |
| `tool/` | Scripts em forma de teste: gerar ícones e renderizar telas |
| `android/app/src/main/kotlin/.../widget` | Widgets nativos (Jetpack Glance) |
| `linux/runner` | Janela GTK, instância única e canal `rumo/desktop` |

## Estado

- `TaskStore` é um `ChangeNotifier` com a lista de tarefas e todas as consultas (atrasadas, hoje, próximos dias, inbox, progresso do dia, próxima tarefa). As telas leem dele e reconstroem com `ListenableBuilder`.
- `FocusTimer` cuida do pomodoro (25/5 min) e das até 3 tarefas escolhidas para o foco.
- `RumoScope` (um `InheritedWidget`) entrega os dois para a árvore inteira, inclusive diálogos e folhas. Acesso: `context.store` e `context.focusTimer`.
- Não há pacote de gerenciamento de estado; se o app crescer, dá para trocar sem mexer nas telas.

## Armazenamento

- `JsonFileRepository` grava `rumo.json` na pasta de dados do app (`getApplicationSupportDirectory`).
- Gravação com atraso de 400 ms depois de cada mudança, e imediata ao minimizar ou fechar.
- Escreve num `.tmp` e renomeia, para o arquivo nunca ficar pela metade. Um arquivo ilegível é copiado para `rumo.json.ilegivel-<data>` em vez de ser sobrescrito.
- `TaskStore.reload()` relê o disco quando o app volta para a frente no Android, porque o widget pode ter concluído tarefas em segundo plano.
- A sincronização na nuvem vai entrar como outra implementação de `TaskRepository` (ver [roteiro.md](roteiro.md)).

Na primeira abertura o app cria cinco tarefas de boas-vindas que ensinam a usá-lo.

## Captura rápida

`lib/util/quick_parser.dart` transforma `pagar aluguel sexta 9h #casa !alta` em título, data, hora, projeto e prioridade.

| Escrito | Vira |
|---|---|
| `hoje`, `amanhã`, `depois de amanhã` | Data relativa |
| `sexta`, `na próxima quarta-feira` | Próxima ocorrência (o próprio dia, se for hoje) |
| `12/10` | Data; vai para o ano seguinte se já passou |
| `9h`, `14:30`, `às 9h30` | Horário |
| `#casa`, `#trab` | Projeto (aceita o começo do nome) |
| `!alta`, `!media`, `!baixa`, `!1` a `!3` | Prioridade |

Acentos e maiúsculas não importam. Projetos desconhecidos e palavras comuns ficam no título.

Sem data nem projeto, a tarefa criada na tela Hoje vai para hoje; criada dentro de um projeto, vai para ele.
