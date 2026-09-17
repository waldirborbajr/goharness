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
