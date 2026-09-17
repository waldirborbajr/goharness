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
