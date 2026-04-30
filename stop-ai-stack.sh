#!/bin/bash
# Arrête la stack IA locale (Ollama, TurboQuant, Open WebUI)

echo "🛑 Arrêt de la stack IA locale..."

# Arrêter Open WebUI (Docker)
if docker ps | grep -q open-webui; then
  echo "  → Arrêt Open WebUI..."
  docker stop open-webui
fi

# Arrêter TurboQuant (processus llama-server)
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
  echo "  → Arrêt TurboQuant..."
  pkill -f "llama-server.*8080"
fi

# Ollama : ne pas arrêter (service système, peut être utilisé par d'autres)
echo "  ℹ️  Ollama laissé actif (service système)"

echo ""
echo "✅ Stack arrêtée (sauf Ollama)"
echo "   Pour tout arrêter : ollama serve (Ctrl+C) si lancé manuellement"
