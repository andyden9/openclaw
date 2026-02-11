#!/bin/bash
set -e

# ==================================================================================
# OpenClaw Monolithic VM Entrypoint (Google Cloud Edition)
# 
# Features:
# 1. Hydrate: Downloads user state from GCS bucket on startup.
# 2. Run: Starts the OpenClaw agent process.
# 3. Persist: Uploads user state back to GCS on shutdown (SIGTERM/SIGINT).
# ==================================================================================

# Configuration
GCS_BUCKET="${GCS_BUCKET:-gs://openclaw-data}"
USER_ID="${USER_ID:-default-user}"
STATE_DIR="${OPENCLAW_STATE_DIR:-/data}"
STATE_ARCHIVE="/tmp/state.tar.gz"
REMOTE_STATE_URI="${GCS_BUCKET}/${USER_ID}/state.tar.gz"

# Colors for logging
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[OpenClaw VM]${NC} $1"
}

finish() {
    log "🛑 Shutdown signal received. Starting persistence..."
    
    # Check if we have anything to save
    if [ -d "$STATE_DIR" ]; then
        log "📦 Archiving state from $STATE_DIR..."
        
        # 1. Archive the state directory
        # We explicitly include sessions.json, memory/, and config.json5 as identified in analysis
        # Using -C to change directory so archive doesn't include full absolute paths
        cd "$STATE_DIR" && tar -czf "$STATE_ARCHIVE" .
        
        # 2. Upload to GCS
        log "☁️ Uploading state to $REMOTE_STATE_URI..."
        if gcloud storage cp "$STATE_ARCHIVE" "$REMOTE_STATE_URI"; then
            log "${GREEN}✅ State persisted successfully.${NC}"
        else
            log "❌ Failed to upload state!"
            exit 1 # Exit with error code to signal failure
        fi
    else
        log "⚠️ State directory $STATE_DIR not found. Nothing to persist."
    fi
    
    exit 0
}

# Trap termination signals to execute 'finish' function
trap finish SIGTERM SIGINT

# ==================================================================================
# Phase 1: Hydrate (Startup)
# ==================================================================================

log "💧 Starting Hydration Phase..."
log "User ID: ${USER_ID}"
log "Bucket: ${GCS_BUCKET}"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Check if remote state exists
if gcloud storage ls "$REMOTE_STATE_URI" > /dev/null 2>&1; then
    log "📥 Found existing state. Downloading..."
    gcloud storage cp "$REMOTE_STATE_URI" "$STATE_ARCHIVE"
    
    log "📂 Extracting state to $STATE_DIR..."
    tar -xzf "$STATE_ARCHIVE" -C "$STATE_DIR"
    log "${GREEN}✅ Hydration complete.${NC}"
else
    log "🆕 No existing state found for user. Starting fresh."
fi

# ==================================================================================
# Phase 2: Run (Execution)
# ==================================================================================

log "🚀 Starting OpenClaw Agent..."

# Generate gateway config (overwrites to ensure no stale settings)
CONFIG_FILE="${STATE_DIR}/openclaw.json"
log "📝 Writing gateway config to $CONFIG_FILE..."
cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "docker-internal"
    }
  }
}
CONFIGEOF
log "✅ Config ready."

# Architecture: Gateway binds to 127.0.0.1 (loopback) so all connections
# are treated as "local" — no auth, no device pairing, no token needed.
# A tiny TCP proxy on 0.0.0.0:8080 forwards external Docker traffic to the gateway.
# This is the correct way to handle Docker's bridge network.

GATEWAY_INTERNAL_PORT=18789

# Start the gateway on loopback (default port, default bind)
npm start -- gateway --port $GATEWAY_INTERNAL_PORT &
GATEWAY_PID=$!

# Wait a moment for gateway to start, then launch the TCP proxy
sleep 2
log "🔗 Starting TCP proxy (0.0.0.0:8080 → 127.0.0.1:$GATEWAY_INTERNAL_PORT)..."
PROXY_PORT=8080 GATEWAY_PORT=$GATEWAY_INTERNAL_PORT node /app/gateway-proxy.mjs &
PROXY_PID=$!

# Wait for either process to exit
wait $GATEWAY_PID $PROXY_PID
