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
