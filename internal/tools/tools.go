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
