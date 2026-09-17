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
