#!/usr/bin/env bash
set -e

PROJECT="go-agent-harness"
rm -rf "$PROJECT" && mkdir -p "$PROJECT"
cd "$PROJECT"

mkdir -p cmd/agent internal/llm internal/tools internal/sandbox internal/context internal/agent docs examples

########################################
# go.mod
########################################
cat > go.mod <<'EOF'
module github.com/seu-usuario/go-agent-harness

go 1.22
EOF

########################################
# README.md
########################################
cat > README.md <<'EOF'
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
EOF

########################################
# docs/ARCHITECTURE.md
########################################
cat > docs/ARCHITECTURE.md <<'EOF'
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
EOF

########################################
# docs/STUDY_GUIDE.md
########################################
cat > docs/STUDY_GUIDE.md <<'EOF'
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
EOF

########################################
# internal/llm/llm.go
########################################
cat > internal/llm/llm.go <<'EOF'
package llm

import "context"

// Message representa uma mensagem no historico do agente.
type Message struct {
	Role    string // "system", "user", "assistant", "tool"
	Content string
}

// ToolCall e um pedido de execucao de ferramenta feito pelo modelo.
type ToolCall struct {
	Name string
	Args map[string]any
}

// Response e a resposta do LLM: ou texto final, ou uma tool call.
type Response struct {
	Text     string
	ToolCall *ToolCall
}

// ToolSpec descreve uma ferramenta para o LLM (nome + descricao).
type ToolSpec struct {
	Name        string
	Description string
}

// Client e a interface que qualquer LLM deve implementar.
// E o que torna o harness agnostico de provedor.
type Client interface {
	Chat(ctx context.Context, messages []Message, tools []ToolSpec) (Response, error)
}
EOF

########################################
# internal/llm/mock.go
########################################
cat > internal/llm/mock.go <<'EOF'
package llm

import (
	"context"
	"fmt"
	"strings"
)

// MockLLM e um LLM falso para testes sem API externa.
// Ele simula: passo 1 -> pede read_file; passo 2 -> responde com resumo.
type MockLLM struct {
	step int
}

func NewMockLLM() *MockLLM { return &MockLLM{} }

func (m *MockLLM) Chat(ctx context.Context, msgs []Message, tools []ToolSpec) (Response, error) {
	m.step++

	// Descobre se ja recebeu resultado de alguma tool
	var lastToolResult string
	for i := len(msgs) - 1; i >= 0; i-- {
		if msgs[i].Role == "tool" {
			lastToolResult = msgs[i].Content
			break
		}
	}

	if lastToolResult == "" {
		// Primeiro passo: pede leitura do arquivo de exemplo
		return Response{
			ToolCall: &ToolCall{
				Name: "read_file",
				Args: map[string]any{"path": "/tmp/agent-workspace/nota.txt"},
			},
		}, nil
	}

	// Segundo passo: resume o conteudo recebido
	resumo := strings.TrimSpace(lastToolResult)
	if len(resumo) > 120 {
		resumo = resumo[:120] + "..."
	}
	return Response{
		Text: fmt.Sprintf("Resumo do arquivo: %s", resumo),
	}, nil
}
EOF

########################################
# internal/sandbox/sandbox.go
########################################
cat > internal/sandbox/sandbox.go <<'EOF'
package sandbox

import (
	"fmt"
	"path/filepath"
	"strings"
)

// Sandbox aplica guardrails antes da execucao de ferramentas.
type Sandbox struct {
	AllowedDir string
}

func New(dir string) *Sandbox {
	abs, _ := filepath.Abs(dir)
	return &Sandbox{AllowedDir: abs}
}

// ValidateRead garante que o caminho esta dentro do diretorio permitido.
func (s *Sandbox) ValidateRead(path string) error {
	abs, err := filepath.Abs(path)
	if err != nil {
		return err
	}
	if !strings.HasPrefix(abs, s.AllowedDir) {
		return fmt.Errorf("acesso negado: %s fora do sandbox (%s)", abs, s.AllowedDir)
	}
	return nil
}

// ValidateCommand bloqueia comandos destrutivos obvios.
func (s *Sandbox) ValidateCommand(cmd string) error {
	blocked := []string{"rm -rf", "shutdown", "mkfs", "dd if=", "> /dev/sd", ":(){:|:&};:"}
	for _, b := range blocked {
		if strings.Contains(cmd, b) {
			return fmt.Errorf("comando bloqueado pelo sandbox: %q", b)
		}
	}
	return nil
}
EOF

########################################
# internal/tools/tools.go
########################################
cat > internal/tools/tools.go <<'EOF'
package tools

import (
	"context"

	"github.com/seu-usuario/go-agent-harness/internal/llm"
)

// Tool e o contrato de qualquer ferramenta do agente.
type Tool interface {
	Name() string
	Description() string
	Execute(ctx context.Context, args map[string]any) (string, error)
}

// Registry guarda todas as ferramentas disponiveis.
type Registry struct {
	tools map[string]Tool
}

func NewRegistry() *Registry {
	return &Registry{tools: make(map[string]Tool)}
}

func (r *Registry) Register(t Tool) {
	r.tools[t.Name()] = t
}

func (r *Registry) Get(name string) (Tool, bool) {
	t, ok := r.tools[name]
	return t, ok
}

// Specs devolve as descricoes para enviar ao LLM.
func (r *Registry) Specs() []llm.ToolSpec {
	var out []llm.ToolSpec
	for _, t := range r.tools {
		out = append(out, llm.ToolSpec{Name: t.Name(), Description: t.Description()})
	}
	return out
}
EOF

########################################
# internal/tools/read_file.go
########################################
cat > internal/tools/read_file.go <<'EOF'
package tools

import (
	"context"
	"fmt"
	"os"

	"github.com/seu-usuario/go-agent-harness/internal/sandbox"
)

type ReadFileTool struct {
	Sandbox *sandbox.Sandbox
}

func (t *ReadFileTool) Name() string        { return "read_file" }
func (t *ReadFileTool) Description() string { return "Le o conteudo de um arquivo dentro do sandbox" }

func (t *ReadFileTool) Execute(ctx context.Context, args map[string]any) (string, error) {
	path, _ := args["path"].(string)
	if path == "" {
		return "", fmt.Errorf("argumento 'path' obrigatorio")
	}
	if err := t.Sandbox.ValidateRead(path); err != nil {
		return "", err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
EOF

########################################
# internal/context/context.go
########################################
cat > internal/context/context.go <<'EOF'
package context

import "github.com/seu-usuario/go-agent-harness/internal/llm"

// Manager controla o historico enviado ao LLM.
// Ponto de extensao natural para compactacao de contexto.
type Manager struct {
	messages  []llm.Message
	maxTokens int
}

func New(systemPrompt string) *Manager {
	return &Manager{
		messages:  []llm.Message{{Role: "system", Content: systemPrompt}},
		maxTokens: 8000,
	}
}

func (m *Manager) Add(msg llm.Message) {
	m.messages = append(m.messages, msg)
}

func (m *Manager) Messages() []llm.Message {
	// TODO: implementar compactacao quando ultrapassar maxTokens.
	return m.messages
}

func (m *Manager) Len() int { return len(m.messages) }
EOF

########################################
# internal/agent/agent.go
########################################
cat > internal/agent/agent.go <<'EOF'
package agent

import (
	"context"
	"fmt"
	"log"

	ctxmgr "github.com/seu-usuario/go-agent-harness/internal/context"
	"github.com/seu-usuario/go-agent-harness/internal/llm"
	"github.com/seu-usuario/go-agent-harness/internal/tools"
)

// Agent e o loop que orquestra LLM <-> ferramentas.
type Agent struct {
	LLM        llm.Client
	Tools      *tools.Registry
	Context    *ctxmgr.Manager
	MaxSteps   int
	OnToolCall func(name string, args map[string]any) // hook opcional
}

func New(client llm.Client, reg *tools.Registry, ctx *ctxmgr.Manager) *Agent {
	return &Agent{
		LLM:      client,
		Tools:    reg,
		Context:  ctx,
		MaxSteps: 10,
	}
}

// Run executa o loop ate o LLM devolver texto final ou estourar MaxSteps.
func (a *Agent) Run(ctx context.Context, task string) (string, error) {
	a.Context.Add(llm.Message{Role: "user", Content: task})

	for step := 0; step < a.MaxSteps; step++ {
		log.Printf("--- passo %d/%d ---", step+1, a.MaxSteps)

		resp, err := a.LLM.Chat(ctx, a.Context.Messages(), a.Tools.Specs())
		if err != nil {
			return "", fmt.Errorf("erro no LLM: %w", err)
		}

		// Caso 1: resposta final
		if resp.ToolCall == nil {
			return resp.Text, nil
		}

		// Caso 2: tool call
		tc := resp.ToolCall
		log.Printf("tool: %s(%v)", tc.Name, tc.Args)

		if a.OnToolCall != nil {
			a.OnToolCall(tc.Name, tc.Args)
		}

		tool, ok := a.Tools.Get(tc.Name)
		if !ok {
			a.Context.Add(llm.Message{
				Role:    "tool",
				Content: fmt.Sprintf("erro: ferramenta %q nao existe", tc.Name),
			})
			continue
		}

		result, err := tool.Execute(ctx, tc.Args)
		if err != nil {
			// Erro volta como mensagem -> LLM pode se auto-corrigir
			a.Context.Add(llm.Message{Role: "tool", Content: "erro: " + err.Error()})
			continue
		}

		a.Context.Add(llm.Message{Role: "tool", Content: result})
	}

	return "", fmt.Errorf("limite de %d passos atingido (guardrail)", a.MaxSteps)
}
EOF

########################################
# cmd/agent/main.go
########################################
cat > cmd/agent/main.go <<'EOF'
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/seu-usuario/go-agent-harness/internal/agent"
	ctxmgr "github.com/seu-usuario/go-agent-harness/internal/context"
	"github.com/seu-usuario/go-agent-harness/internal/llm"
	"github.com/seu-usuario/go-agent-harness/internal/sandbox"
	"github.com/seu-usuario/go-agent-harness/internal/tools"
)

const workspace = "/tmp/agent-workspace"

func main() {
	// Garante que o workspace existe e tem um arquivo de exemplo
	if err := os.MkdirAll(workspace, 0o755); err != nil {
		log.Fatal(err)
	}
	nota := workspace + "/nota.txt"
	if _, err := os.Stat(nota); os.IsNotExist(err) {
		_ = os.WriteFile(nota, []byte(
			"Este e um arquivo de exemplo criado automaticamente.\n"+
				"Ele serve para testar o harness do agente.\n",
		), 0o644)
	}

	// === Composicao do Harness ===
	sb := sandbox.New(workspace)

	reg := tools.NewRegistry()
	reg.Register(&tools.ReadFileTool{Sandbox: sb})

	client := llm.NewMockLLM() // troque por OpenAI/Claude/Ollama

	ctxMgr := ctxmgr.New("Voce e um agente. Use ferramentas quando necessario. Responda em portugues.")

	ag := agent.New(client, reg, ctxMgr)

	// === Execucao ===
	resposta, err := ag.Run(context.Background(),
		fmt.Sprintf("Leia o arquivo %s/nota.txt e resuma em uma frase.", workspace))
	if err != nil {
		log.Fatalf("erro: %v", err)
	}

	fmt.Println("\nResposta final:", resposta)
}
EOF

########################################
# examples/nota.txt
########################################
cat > examples/nota.txt <<'EOF'
Este e um arquivo de exemplo para testes do harness.
Ele demonstra como o agente le arquivos dentro do sandbox.
EOF

########################################
# .gitignore
########################################
cat > .gitignore <<'EOF'
*.zip
/tmp/
.DS_Store
EOF

########################################
# Gera o ZIP
########################################
cd ..
ZIPNAME="go-agent-harness.zip"
rm -f "$ZIPNAME"
zip -r "$ZIPNAME" "$PROJECT" -x "*/.*" > /dev/null

echo ""
echo "Projeto criado em: ./$PROJECT/"
echo "ZIP gerado em:     ./$ZIPNAME"
echo ""
echo "Para rodar:"
echo "  cd $PROJECT && go run ./cmd/agent"
echo ""