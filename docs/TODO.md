# TODO — Go Agent Harness

Roadmap de evolução do harness didático para um agente funcional.

**Legenda:**
- `[ ]` pendente
- `[x]` concluído
- `[~]` em andamento
- 🔴 bloqueante · 🟡 importante · 🟢 nice-to-have

---

## ✅ Fase 0 — Fundação (feito)

- [x] Estrutura de pacotes (`cmd/`, `internal/{agent,llm,tools,sandbox,context}`)
- [x] Interface `llm.Client` desacoplada
- [x] `MockLLM` para testar sem API
- [x] `Registry` de ferramentas
- [x] `Sandbox` com `ValidateRead` e `ValidateCommand`
- [x] `ContextManager` básico
- [x] Loop do agente com `MaxSteps`
- [x] `ReadFileTool` como ferramenta de exemplo
- [x] Dev Container (Go + gopls + golangci-lint + dlv + air + just)
- [x] Documentação (`README.md`, `ARCHITECTURE.md`, `STUDY_GUIDE.md`)

---

## 🔧 Fase 1 — Higiene do repositório

- [ ] 🔴 Trocar `github.com/seu-usuario/go-agent-harness` por `github.com/waldirborbajr/goharness` em todos os `.go` e no `go.mod`
- [ ] 🔴 `go mod tidy` e commit inicial
- [ ] 🟡 Resolver o hook do Git LFS (`rm -f .git/hooks/pre-push` ou instalar `git-lfs`)
- [ ] 🟡 Criar `justfile` com `build`, `run`, `test`, `lint`, `fmt`, `vet`, `vuln`, `check`, `dev`, `clean`
- [ ] 🟡 Adicionar `.editorconfig`
- [ ] 🟢 Adicionar `LICENSE` (MIT ou Apache-2.0)
- [ ] 🟢 Adicionar `CONTRIBUTING.md`
- [ ] 🟢 Criar `Makefile` espelhando o `justfile` (para quem não tem `just`)

---

## 🧪 Fase 2 — Testes

- [ ] 🟡 `internal/sandbox/sandbox_test.go`
  - [ ] Caminho dentro do sandbox → OK
  - [ ] Caminho fora do sandbox → erro
  - [ ] Path com `..` → bloqueado
  - [ ] Comando perigoso → bloqueado
- [ ] 🟡 `internal/tools/read_file_test.go`
  - [ ] Arquivo existente → retorna conteúdo
  - [ ] Arquivo fora do sandbox → erro
  - [ ] Args inválidos → erro
- [ ] 🟡 `internal/agent/agent_test.go`
  - [ ] Loop termina em texto final
  - [ ] Loop respeita `MaxSteps`
  - [ ] Tool inexistente → mensagem de erro volta ao contexto
  - [ ] Erro de tool → mensagem de erro volta ao contexto
- [ ] 🟢 `internal/context/context_test.go`
- [ ] 🟢 Cobertura mínima de 70% (`go test -cover ./...`)
- [ ] 🟢 Adicionar `gotestsum` no `just test`

---

## 🤖 Fase 3 — LLM real

Escolha **uma** trilha (ou as duas) para estudar:

### Trilha A — Ollama (local, grátis, sem API key) 🟢 recomendado

- [ ] Instalar Ollama dentro do container
- [ ] `ollama pull llama3.2` (ou `qwen2.5`, `mistral`)
- [ ] Criar `internal/llm/ollama.go` implementando `llm.Client`
- [ ] Mapear `llm.Message` ↔ formato Ollama
- [ ] Mapear `llm.ToolSpec` ↔ formato de tools do Ollama
- [ ] Parsear `tool_calls` da resposta
- [ ] Testar com o mesmo prompt do mock
- [ ] Adicionar flag `--provider` em `cmd/agent/main.go`

### Trilha B — OpenAI / Anthropic

- [ ] `go get github.com/sashabaranov/go-openai` (ou SDK da Anthropic)
- [ ] Criar `internal/llm/openai.go` implementando `llm.Client`
- [ ] Ler API key de env (`OPENAI_API_KEY`)
- [ ] Tratar rate limit e retries com backoff
- [ ] Testar com `gpt-4o-mini` (barato)

### Comum às duas trilhas

- [ ] 🟡 Seleção de provider via variável de ambiente (`LLM_PROVIDER=ollama|openai`)
- [ ] 🟢 Streaming de tokens (interface `ChatStream`)

---

## 🛠️ Fase 4 — Ferramentas reais

- [ ] 🟡 `ListDirTool` — listar diretório (com validação de sandbox)
- [ ] 🟡 `WriteFileTool` — escrever arquivo (com validação de sandbox + aprovação)
- [ ] 🟡 `AppendFileTool` — anexar a arquivo (útil para scratchpad)
- [ ] 🟡 `HTTPGetTool` — requisição HTTP com timeout
  - [ ] Whitelist de domínios
  - [ ] Limite de tamanho da resposta
- [ ] 🟢 `ExecCommandTool` — rodar comando shell
  - [ ] Whitelist de binários permitidos
  - [ ] `context.WithTimeout`
  - [ ] Captura de stdout/stderr
  - [ ] Aprovação humana obrigatória
- [ ] 🟢 `GrepTool` — busca em arquivos (usando `ripgrep`)
- [ ] 🟢 `SQLiteTool` — consultas ao banco local

---

## 🧠 Fase 5 — Contexto e memória

- [ ] 🟡 **Compactação de contexto**
  - [ ] Estimar tokens (`tiktoken` ou heurística ~4 chars/token)
  - [ ] Quando passar de `maxTokens`, resumir mensagens antigas via LLM
  - [ ] Preservar sempre: system prompt + últimas N mensagens + tool results recentes
- [ ] 🟡 **Scratchpad**
  - [ ] Ferramenta `write_scratchpad` / `read_scratchpad`
  - [ ] Agente anota progresso entre passos
- [ ] 🟢 **Memória persistente**
  - [ ] Interface `MemoryStore`
  - [ ] Implementação SQLite (`modernc.org/sqlite`, sem CGO)
  - [ ] Implementação em arquivo JSON (para estudar)
  - [ ] Salvar: tarefa, passos, resultado final
- [ ] 🟢 **Memória semântica** (embeddings)
  - [ ] Gerar embeddings das interações passadas
  - [ ] Buscar top-K relevante ao prompt atual
  - [ ] Injetar no contexto

---

## 🛡️ Fase 6 — Guardrails avançados

- [ ] 🔴 **Aprovação humana (human-in-the-loop)**
  - [ ] Hook `OnToolCall` que pede `y/n` no terminal
  - [ ] Lista de tools "destrutivas" que exigem aprovação
  - [ ] Timeout para a resposta do humano
- [ ] 🟡 **Timeout por execução** (`context.WithTimeout` em `tool.Execute`)
- [ ] 🟡 **Rate limiting** por ferramenta
- [ ] 🟡 **Orçamento de tokens** — abortar se passar de X tokens gastos
- [ ] 🟡 **Orçamento de tempo** — abortar se passar de X minutos
- [ ] 🟢 **Auditoria** — log estruturado (JSON) de toda tool call
- [ ] 🟢 **Dry-run** — modo que simula execução sem efeitos colaterais

---

## 🚀 Fase 7 — Recursos "de harness real"

- [ ] 🟢 **Streaming de tokens** para o usuário
- [ ] 🟢 **Paralelismo** — múltiplas tool calls em uma só resposta
- [ ] 🟢 **MCP (Model Context Protocol)**
  - [ ] Cliente MCP para ferramentas externas
  - [ ] Adaptar `Tool` para consumir servidor MCP
- [ ] 🟢 **Sub-agentes**
  - [ ] Um agente que invoca outros agentes como ferramenta
  - [ ] Passagem de contexto entre eles
- [ ] 🟢 **Observabilidade**
  - [ ] Traces com OpenTelemetry
  - [ ] Métricas: passos por tarefa, tokens, latência, custo
- [ ] 🟢 **Retry inteligente** — se tool falhar, agente reformula args

---

## 📚 Fase 8 — Estudo e documentação contínua

- [ ] 🟡 Ler e resumir em `docs/notes/`:
  - [ ] Anthropic — "Building effective agents"
  - [ ] Especificação do MCP
  - [ ] Padrão ReAct (Yao et al.)
  - [ ] Padrão Reflexion
  - [ ] Padrão Plan-and-Execute
- [ ] 🟢 Adicionar `docs/notes/` ao repositório
- [ ] 🟢 Escrever post/blog explicando o harness
- [ ] 🟢 Gravar screencast do agente resolvendo uma tarefa real

---

## 🎯 Projeto Final (meta)

Construir um agente que:

- [ ] Recebe tarefa em linguagem natural: *"crie um README para o diretório X"*
- [ ] Usa `list_dir`, `read_file`, `write_file`
- [ ] Auto-verifica o resultado relendo o arquivo criado
- [ ] Tem limite de 15 passos
- [ ] Pede aprovação humana antes de escrever
- [ ] Salva o histórico da execução em SQLite
- [ ] Usa um LLM real (Ollama ou OpenAI)

---

## 📌 Ordem sugerida de execução

```
Fase 1 (higiene)
   ↓
Fase 2 (testes) ────┐
   ↓                │
Fase 3 (LLM real)   │  ← pode paralelizar
   ↓                │
Fase 4 (tools)  ────┘
   ↓
Fase 5 (contexto/memória)
   ↓
Fase 6 (guardrails)
   ↓
Fase 7 (recursos avançados)
   ↓
Fase 8 (documentação)
   ↓
🎯 Projeto Final
```