# Roteiro

## Feito

1. **Base do app:** telas Hoje, Próximos, Inbox, Projetos e Foco, captura rápida, detalhe da tarefa, dados locais, layout para computador.
2. **Widgets do Android:** Hoje, A seguir, Progresso e Adicionar.
3. **Computador:** instância única, atalho global, bandeja e mini janela de foco.

## Próximo: sincronização

Celular e computador com os mesmos dados, por um serviço na nuvem. Opção sugerida: Supabase (banco e login prontos), entrando como outra implementação de `TaskRepository`. Falta decidir onde hospedar.

## Depois

- Instalação no Linux de verdade (pacote, atalho no menu e no dock sem script).
- Projetos editáveis (hoje são fixos: Trabalho, Casa, Saúde, Estudos).
- Recorrência que gera a próxima tarefa (hoje só aparece na tarefa).
- Fontes embutidas no app.
