# Guia de Estudos — Harness em Go

## Fase 1 — Entender o esqueleto
1. Leia `internal/agent/agent.go`. E o **coração**. Entenda cada passo.
2. Rode `go run ./cmd/agent` e observe os logs.
3. Quebre de proposito: mude o `maxSteps`, remova o sandbox, veja o que acontece.

## Fase 2 — Adicionar ferramentas
Crie novas tools em `internal/tools/`:
- `WriteFileTool` — escrever arquivos (com validacao de sandbox)
- `ListDirTool` — listar diretorio
- `HTTPGetTool` — fazer requisicao HTTP
- `ExecCommandTool` — rodar comando shell (cuidado!)

Registre em `cmd/agent/main.go` e teste.

## Fase 3 — Trocar o LLM
Substitua `MockLLM` por um cliente real:
- OpenAI (`github.com/sashabaranov/go-openai`)
- Anthropic Claude
- Ollama local (`github.com/ollama/ollama/api`)

O ponto-chave: **so mude a implementacao de `LLMClient`**. O harness nao muda.

## Fase 4 — Contexto e memoria
- Implemente compactacao: quando `len(messages) > N`, resuma os antigos.
- Persista o historico em disco (JSON ou SQLite).
- Adicione um "scratchpad" — arquivo onde o agente anota progresso.

## Fase 5 — Guardrails avancados
- Aprovacao humana: antes de executar tool destrutiva, pede `y/n`.
- Rate limiting por ferramenta.
- Timeout por execucao (`context.WithTimeout`).
- Whitelist de comandos shell.

## Fase 6 — Recursos de harness "real"
- **Streaming** de tokens para o usuario
- **MCP** (Model Context Protocol) para ferramentas externas
- **Paralelismo**: multiplas tool calls em uma so resposta
- **Observabilidade**: traces com OpenTelemetry
- **Sub-agentes**: um agente que invoca outros agentes

## Leituras recomendadas
- Anthropic — "Building effective agents"
- Model Context Protocol (MCP) spec
- Padroes: ReAct, Reflexion, Plan-and-Execute

## Exercicio final
Construa um agente que:
1. Recebe uma tarefa em linguagem natural ("crie um README para o diretorio X")
2. Usa `list_dir`, `read_file`, `write_file`
3. Auto-verifica o resultado relendo o arquivo criado
4. Tem limite de 15 passos e pede aprovacao antes de escrever
