#!/usr/bin/env bash
set -e

MODEL="${1:-llama3.2:1b}"

echo "==> Subindo container do Ollama..."
docker compose up -d

echo "==> Aguardando o serviço ficar pronto..."
until curl -s http://localhost:11434 >/dev/null; do
  sleep 1
done

echo "==> Baixando modelo leve: ${MODEL}"
docker exec -it goharness-ollama ollama pull "${MODEL}"

echo "==> Pronto! Teste com:"
echo "curl http://localhost:11434/api/generate -d '{\"model\": \"${MODEL}\", \"prompt\": \"ola\"}'"