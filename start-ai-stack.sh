#!/bin/bash

echo "🚀 Démarrage de la stack IA locale (Ollama + TurboQuant + LibreChat)..."

# 1. Vérifier que Docker tourne
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker n'est pas lancé. Démarrage de Docker Desktop..."
    open -a Docker
    sleep 10
fi

# 2. Démarrer LibreChat (Docker)
echo "📦 Démarrage LibreChat..."
cd ~/dev/librechat
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d

# 3. Démarrer TurboQuant server
echo "⚡ Démarrage TurboQuant server (KV cache compressé)..."
if ! curl -s http://localhost:8080/health > /dev/null; then
    cd ~/dev/llama-cpp-turboquant
    nohup ./build/bin/llama-server \
        -m ~/dev/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf \
        -c 131072 \
        -ctk turbo4 \
        -ctv turbo4 \
        --host 0.0.0.0 \
        --port 8080 \
        --log-disable > /tmp/turboquant.log 2>&1 &
    echo "TurboQuant PID: $!"
else
    echo "✅ TurboQuant server déjà en cours"
fi

# 4. Vérifier Ollama
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "⚠️  Ollama n'est pas lancé. Démarrage..."
    ollama serve &
    sleep 3
fi

echo ""
echo "✅ Stack démarrée !"
echo "   - LibreChat : http://localhost:3080"
echo "   - Ollama API : http://localhost:11434"
echo "   - TurboQuant : http://localhost:8080"
echo ""
echo "📊 Pour voir les logs TurboQuant : tail -f /tmp/turboquant.log"
echo "📊 Pour voir les logs LibreChat : cd ~/dev/librechat && docker compose logs -f"
