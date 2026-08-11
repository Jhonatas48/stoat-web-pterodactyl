#!/usr/bin/env bash
set -Eeuo pipefail

cd /home/container

export HOME=/home/container
export PATH="/usr/local/bin:$PATH"
export XDG_CACHE_HOME=/home/container/.cache
export PNPM_STORE_DIR=/home/container/.pnpm-store

log() {
    printf '[stoat-web] %s\n' "$*"
}

if [[ ! -d source/.git ]]; then
    log "fonte ausente; reinstale o servidor pelo painel"
    exit 1
fi

mkdir -p .cache .pnpm-store

if [[ "${PULL_ON_START:-0}" == "1" ]]; then
    log "atualizando ${GIT_BRANCH:-main}"
    git -C source fetch origin "${GIT_BRANCH:-main}"
    git -C source merge --ff-only "origin/${GIT_BRANCH:-main}"
    git -C source submodule sync --recursive
    git -C source submodule update --init --recursive \
        packages/stoat.js packages/solid-livekit-components
fi

SERVER_PORT="${SERVER_PORT:-14701}"

cat > source/packages/client/.env <<EOF
VITE_HOST=${INSTANCE_HOST:-127.0.0.1:${SERVER_PORT}}
VITE_API_URL=${API_URL:-http://127.0.0.1:14702}
VITE_DEV_WS_URL=${WS_URL:-ws://127.0.0.1:14703}
VITE_DEV_MEDIA_URL=${MEDIA_URL:-http://127.0.0.1:14704}
VITE_DEV_PROXY_URL=${PROXY_URL:-http://127.0.0.1:14705}
VITE_DEV_GIFBOX_URL=${GIFBOX_URL:-http://127.0.0.1:14706}
VITE_SENTRY_DSN=
VITE_SENTRY_TUNNEL=
EOF

cd source
pnpm config set store-dir /home/container/.pnpm-store

lock_hash="$(sha256sum pnpm-lock.yaml | awk '{print $1}')"
deps_marker="/home/container/.cache/dependencies-${lock_hash}"

if [[ "${INSTALL_ON_START:-0}" == "1" || ! -d node_modules || ! -f "$deps_marker" ]]; then
    log "instalando dependências congeladas"
    pnpm install --frozen-lockfile

    log "compilando stoat.js e componentes LiveKit"
    pnpm --filter stoat.js build
    pnpm --filter solid-livekit-components build
    pnpm --filter client exec lingui compile --typescript
    pnpm --filter client exec node scripts/copyAssets.mjs
    pnpm --filter client exec panda codegen

    touch "$deps_marker"
    log "dependências prontas"
fi

case "${APP_MODE:-development}" in
    development)
        log "Vite pronto na porta ${SERVER_PORT} em modo development"
        exec pnpm --filter client exec vite \
            --host 0.0.0.0 \
            --port "$SERVER_PORT" \
            --strictPort
        ;;
    preview)
        if [[ "${BUILD_ON_START:-1}" == "1" || ! -d packages/client/dist ]]; then
            log "gerando build do frontend"
            pnpm --filter client exec lingui compile --typescript
            pnpm --filter client exec node scripts/copyAssets.mjs
            pnpm --filter client exec panda codegen
            pnpm --filter client exec vite build
        fi

        log "Vite pronto na porta ${SERVER_PORT} em modo preview"
        exec pnpm --filter client exec vite preview \
            --host 0.0.0.0 \
            --port "$SERVER_PORT" \
            --strictPort
        ;;
    *)
        log "APP_MODE inválido: ${APP_MODE}; use development ou preview"
        exit 64
        ;;
esac
