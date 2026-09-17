# Arquitetura do Harness

## 1. Visao Geral

Um harness e a **infraestrutura fora dos pesos do modelo** que transforma
um LLM (gerador de texto) em um agente funcional (executor de tarefas).

## 2. Fluxo de Execucao

```
   +--------------+
   | Tarefa (user)|
   +------+-------+
          v
   +------------------+
   | ContextManager   |  <- historico + system prompt
   +------+-----------+
          v
   +------------------+
   |    LLMClient     |  <- decide: texto final OU tool call
   +------+-----------+
          |
   +------+--------+
   |               |
   v               v
[Text]         [ToolCall]
   |               |
   |               v
   |        +--------------+
   |        |   Registry   |  <- encontra a tool
   |        +------+-------+
   |               v
   |        +--------------+
   |        |   Sandbox    |  <- valida guardrails
   |        +------+-------+
   |               v
   |        +--------------+
   |        |   Execute    |
   |        +------+-------+
   |               v
   |        +--------------+
   |        |  Result/Err  |  <- volta como mensagem
   |        +------+-------+
   |               |
   +-------<-------+
          (loop)
```

## 3. Responsabilidades

### Agent Loop (`internal/agent`)
- Conduz o ciclo: LLM -> tool -> LLM -> ...
- Aplica `maxSteps` (guardrail contra loop infinito)
- Decide quando terminar (resposta textual sem tool call)

### LLM Client (`internal/llm`)
- **Interface** `LLMClient` — permite trocar provedor sem tocar no resto
- `MockLLM` para testes sem API

### Tools Registry (`internal/tools`)
- `Tool` e uma interface: `Name`, `Description`, `Execute`
- `Registry` guarda e busca ferramentas por nome
- O LLM so ve nome + descricao (nao ve implementacao)

### Sandbox (`internal/sandbox`)
- Guardrails **antes** da execucao
- `ValidateRead`: bloqueia acesso fora do diretorio permitido
- `ValidateCommand`: bloqueia comandos perigosos

### Context Manager (`internal/context`)
- Mantem o historico de mensagens (system, user, assistant, tool)
- Ponto de extensao para **compactacao** quando estourar tokens

## 4. Principios de Design

1. **Separacao de responsabilidades** — cada pacote tem uma funcao clara.
2. **Inversao de dependencia** — o loop depende de interfaces, nao de implementacoes.
3. **Guardrails no ponto de execucao** — o sandbox fica dentro da tool, nao no loop.
4. **Erros como dados** — falhas voltam ao LLM como mensagens, nao como `panic`.
5. **Limites explicitos** — `maxSteps` evita loops infinitos.

## 5. Pontos de Extensao

| Onde | Como estender |
|---|---|
| Novas ferramentas | Implementar `Tool` e registrar |
| Novo LLM | Implementar `LLMClient` |
| Compactacao de contexto | Modificar `ContextManager.Messages()` |
| Aprovacao humana | Adicionar callback antes de `tool.Execute` |
| Memoria persistente | Injetar store no `ContextManager` |
| Streaming | Estender `LLMClient.Chat` para canal |
