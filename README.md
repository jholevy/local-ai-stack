# Local AI Stack - Ollama + TurboQuant + Open WebUI + LibreChat

Configuration clé en main pour une stack IA locale sur Mac Apple Silicon, utilisant :
- **Ollama** (modèles standards, rapides, optimisés Metal)
- **TurboQuant** (fork llama.cpp avec KV cache compressé turbo4, contextes longs 8k-16k)
- **Open WebUI** (interface web moderne, remplace LibreChat)
- **LibreChat** (alternative interface, support multi-provider avancé)

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  Open WebUI (localhost:3000)  │  LibreChat (localhost:3080) │
│  Interface web multi-provider  │  Alt. interface, agents     │
└──────────────┬──────────────────┬──────────────────┬─────────┘
               │                  │                  │
               ▼                  ▼                  ▼
    ┌──────────────┐    ┌──────────────────┐    ┌──────────┐
    │   Ollama     │    │  TurboQuant      │    │ MongoDB  │
    │ :11434       │    │  llama.cpp       │    │ :27017   │
    │              │    │  server :8080    │    │ Sessions │
    │ - qwen2.5:14b│    │  -ctk turbo4    │    └──────────┘
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

### 1. Cloner TurboQuant (fork avec KV cache compressé)
```bash
cd ~/dev
git clone https://github.com/TheTom/llama-cpp-turboquant
cd llama-cpp-turboquant
cmake -B build -DLLAMA_METAL=ON
cmake --build build --config Release -j
```

### 2. Télécharger modèles GGUF
```bash
huggingface-cli download TheBloke/Qwen2.5-14B-Instruct-GGUF \
  --include "qwen2.5-14b-instruct-q4_k_m.gguf" \
  --local-dir ~/dev/models
```

### 3. Démarrer Open WebUI
```bash
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v ~/dev/open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

### 4. Démarrer LibreChat (v0.8.5)
```bash
# Créer le dossier de config
mkdir -p ~/dev/librechat

# Copier librechat.yaml depuis ce repo
cp librechat-config/librechat.yaml ~/dev/librechat/
cp librechat-config/.env.example ~/dev/librechat/.env
# Éditer ~/dev/librechat/.env avec vos secrets JWT !

# Démarrer MongoDB
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=mongodb \
  -e MONGO_INITDB_ROOT_PASSWORD=your_password_here \
  mongo:latest

# Démarrer LibreChat
docker run -d \
  --name librechat \
  -p 3080:3080 \
  --link mongodb:mongodb \
  -v ~/dev/librechat/librechat.yaml:/app/librechat.yaml \
  -v ~/dev/librechat/.env:/app/.env \
  -e MONGO_URI="mongodb://mongodb:27017/librechat" \
  -e JWT_SECRET=your_64char_secret_here \
  -e JWT_REFRESH_SECRET=your_64char_refresh_secret_here \
  registry.librechat.ai/danny-avila/librechat-dev:latest
```

### 5. Lancer la stack complète
```bash
./start-ai-stack.sh
```

## Configuration LibreChat

⚠️ **Leçon critique (2026-05-01)** :
- `generateRefreshToken()` dans `session.es.js` utilise `JWT_REFRESH_SECRET` (pas `JWT_SECRET` !)
- **Les deux variables doivent être définies** dans le conteneur Docker
- Sinon erreur : `JsonWebTokenError: secretOrPrivateKey must have a value`

Fichiers de config dans `librechat-config/` :
- `librechat.yaml` : Configuration v1.3.9, providers Ollama + TurboQuant
- `.env.example` : Template des variables d'environnement

## Utilisation

### Open WebUI (http://localhost:3000)
1. Créer le premier compte (admin automatique)
2. Dans Admin Settings > Connections, ajouter TurboQuant :
   - URL : `http://host.docker.internal:8080/v1`
   - API Key : `dummy`
3. Choisir Ollama ou TurboQuant dans l'interface

### LibreChat (http://localhost:3080)
1. Créer le premier compte (admin automatique avec `REGISTRATION_OPEN=true`)
2. Sélectionner un modèle dans la liste (Ollama Local ou TurboQuant Local)
3. ⚠️ Ne pas utiliser "My Agents" par défaut, choisir directement le modèle

## Benchmarks

| Moteur | Modèle | Config | Vitesse | Contexte max |
|---------|--------|--------|---------|--------------|
| **Ollama** | qwen2.5:14b | GPU/Metal natif | **13.6 t/s** ✅ | 4k ❌ VRAM |
| **TurboQuant** | Qwen2.5-14B | GPU + turbo4 (ctx=2048) | **11.8 t/s** | 8k ✅ |
| **TurboQuant** | Qwen2.5-14B | GPU + turbo4 (ctx=8192) | **12.83 t/s** | **5630 tokens testés** ✅ |
| **TurboQuant** | Qwen2.5-3B | GPU + turbo4 (ctx=8192) | **45-55 t/s** ✅ | 8k+ |

**Test réel (2026-04-30)** :
- TurboQuant 14B + ctx 8192 : 5530 tokens prompt + 100 tokens générés = **5630 tokens sans crash VRAM** ✅
- TurboQuant 14B + ctx 16384 (16k) : **10241 tokens prompt + 97 tokens = 10338 tokens totaux** ✅ (testé en direct)
- Ollama 14B : crash dès 4k tokens (VRAM saturée)
- **Avantage TurboQuant** : KV cache turbo4 (4-bit) économise ~75% VRAM → contextes 16k+ possibles

**Vitesse moyenne (10241 tokens prompt)** : ~128 tokens/seconde en prompt processing

## Scripts

- `start-ai-stack.sh` : Démarre Ollama, TurboQuant, Open WebUI (LibreChat à ajouter)
- `stop-ai-stack.sh` : Arrête tous les services
- `librechat-config/` : Configurations pour LibreChat

## Documentation complète

Le coffre Obsidian contient la documentation détaillée :
- `02-Projets/TurboQuant-Local/LibreChat-Installation-Lessons-Learned.md` : Leçons apprises installation LibreChat
- `02-Projets/TurboQuant-Local/TurboQuant-LibreChat-Plan-B.md` : Plan de déploiement
- `02-Projets/Training IA/TikTok/` : Notes sur les vidéos TikTok (ex: extraction contenu)

## Licence

MIT (pour les scripts et configs de ce repo)
