package tools

import (
	"context"
	"fmt"
	"os"

	"github.com/waldirborbajr/goharness/internal/sandbox"
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
