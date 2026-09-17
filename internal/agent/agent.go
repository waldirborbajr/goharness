package agent

import (
	"context"
	"fmt"
	"log"

	ctxmgr "github.com/waldirborbajr/goharness/internal/context"
	"github.com/waldirborbajr/goharness/internal/llm"
	"github.com/waldirborbajr/goharness/internal/tools"
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
