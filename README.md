# Local AI Stack - Ollama + TurboQuant + Open WebUI

Configuration clé en main pour une stack IA locale sur Mac Apple Silicon, utilisant :
- **Ollama** (modèles standards, rapides, optimisés Metal)
- **TurboQuant** (fork llama.cpp avec KV cache compressé turbo4, contextes longs 8k-16k)
- **Open WebUI** (interface web moderne, remplace LibreChat)

## Architecture

```
┌─────────────────────────────────────────────┐
│         Open WebUI (localhost:3000)        │
│         Interface web multi-provider        │
└──────────────┬──────────────────┬──────────┘
               │                  │
               ▼                  ▼
    ┌──────────────┐    ┌──────────────────┐
    │   Ollama     │    │  TurboQuant      │
    │ :11434       │    │  llama.cpp       │
    │              │    │  server :8080    │
    │ - qwen2.5:14b│    │  -ctk turbo4    │
    │ - llama3.2   │    │  -ctv turbo4    │
    │ - mistral    │    │  - ctx 8192     │
    └──────────────┘    └──────────────────┘
```

## Pré-requis

- macOS Apple Silicon (M1/M2/M3/M4)
- Docker Desktop
- CMake >= 3.21
- Clang (Xcode command line tools)
- Ollama installé

## Installation rapide

```bash
# 1. Cloner TurboQuant (fork avec KV cache compressé)
cd ~/dev
git clone https://github.com/TheTom/llama-cpp-turboquant
cd llama-cpp-turboquant
cmake -B build -DLLAMA_METAL=ON
cmake --build build --config Release -j

# 2. Télécharger modèles GGUF
huggingface-cli download TheBloke/Qwen2.5-14B-Instruct-GGUF \
  --include "qwen2.5-14b-instruct-q4_k_m.gguf" \
  --local-dir ~/dev/models

# 3. Démarrer Open WebUI
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v ~/dev/open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# 4. Lancer la stack complète
./start-ai-stack.sh
```

## Utilisation

1. Ouvrir http://localhost:3000
2. Créer le premier compte (admin automatique)
3. Dans Admin Settings > Connections, ajouter TurboQuant :
   - URL : `http://host.docker.internal:8080/v1`
   - API Key : `dummy`
4. Choisir Ollama ou TurboQuant dans l'interface

## Benchmarks

| Moteur | Modèle | Config | Vitesse | Contexte max |
|---------|--------|--------|---------|--------------|
| **Ollama** | qwen2.5:14b | GPU/Metal natif | **13.6 t/s** ✅ | 4k ❌ VRAM |
| **TurboQuant** | Qwen2.5-14B | GPU + turbo4 (ctx=2048) | **11.8 t/s** | 8k ✅ |
| **TurboQuant** | Qwen2.5-14B | GPU + turbo4 (ctx=8192) | **12.83 t/s** | **5630 tokens testés** ✅ |
| **TurboQuant** | Qwen2.5-3B | GPU + turbo4 (ctx=8192) | **45-55 t/s** ✅ | 8k+ |

**Test réel (2026-04-30)** :
- TurboQuant 14B + ctx 8192 : 5530 tokens prompt + 100 tokens générés = **5630 tokens sans crash VRAM** ✅
- Ollama 14B : crash dès 4k tokens (VRAM saturée)
- **Avantage TurboQuant** : KV cache turbo4 (4-bit) économise ~75% VRAM → contextes longs possibles

## Scripts

- `start-ai-stack.sh` : Démarre Ollama, TurboQuant, Open WebUI
- `stop-ai-stack.sh` : Arrête tous les services

## Licence

MIT (pour les scripts et configs de ce repo)
