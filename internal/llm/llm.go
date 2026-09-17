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
