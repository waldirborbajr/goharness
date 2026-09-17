# Go Agent Harness — Exemplo Didático

Um **harness** minimalista em Go para agentes de IA.
Demonstra a arquitetura essencial: loop do agente, registro de ferramentas,
sandbox (guardrails), gerenciamento de contexto e cliente LLM plugável.

## Arquitetura

```
+---------------------------------------------+
|                 HARNESS                     |
|                                             |
|  +----------+   +----------+   +---------+  |
|  |  Agent   |-->|  Tools   |-->| Sandbox |  |
|  |   Loop   |   | Registry |   |  Guard  |  |
|  +----+-----+   +----------+   +---------+  |
|       |                                     |
|       v                                     |
|  +----------+   +----------+                |
|  | Context  |<->|   LLM    |                |
|  | Manager  |   |  Client  |                |
|  +----------+   +----------+                |
+---------------------------------------------+
```

## Estrutura

```
go-agent-harness/
|-- cmd/agent/main.go           # ponto de entrada
|-- internal/
|   |-- agent/agent.go          # loop do agente
|   |-- llm/llm.go              # interface + mock
|   |-- tools/tools.go          # registry + ferramentas
|   |-- sandbox/sandbox.go      # guardrails
|   `-- context/context.go      # gerenciamento de contexto
|-- docs/
|   |-- ARCHITECTURE.md
|   `-- STUDY_GUIDE.md
`-- examples/
    `-- nota.txt
```

## Como rodar

```bash
go run ./cmd/agent
```

## Conceitos demonstrados

| Componente | Papel |
|---|---|
| **Loop do Agente** | Orquestra LLM <-> ferramentas ate concluir |
| **Registry** | Desacopla o LLM das ferramentas |
| **Sandbox** | Guardrails: valida antes de executar |
| **ContextManager** | Controla o historico enviado ao modelo |
| **LLMClient (interface)** | Permite trocar GPT/Claude/Ollama/mock |

## Insights

1. O LLM **nunca** executa nada — ele so *pede* (`ToolCall`).
2. Erros voltam como **mensagens**, permitindo auto-correcao.
3. O sandbox fica **dentro da tool**, nao no loop.
4. A interface `LLMClient` torna o harness **agnostico de modelo**.
5. O loop tem **limite de passos** (guardrail contra loop infinito).

## Proximos passos de estudo

- Compactacao de contexto (resumo quando estourar tokens)
- Memoria persistente (SQLite, arquivos)
- MCP (Model Context Protocol) para ferramentas externas
- Streaming de tokens
- Aprovacao humana (human-in-the-loop)
- Multiplas ferramentas: shell, HTTP, SQL
