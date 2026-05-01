#!/usr/bin/env bash
# Creates ONLY the Spanish Assistant. Used because the English assistant was
# already created on a prior run (we don't want a duplicate).
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-create-spanish.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${VAPI_PRIVATE_KEY:-}" ]]; then
  echo "ERROR: VAPI_PRIVATE_KEY not set"
  exit 1
fi

VAPI_API="https://api.vapi.ai"
JSON_FILE="$PROJECT_ROOT/agent/spanish_assistant.json"
OUT_BODY="/tmp/vapi_spanish_body.json"

echo "==> Creating Spanish Assistant..."
HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X POST "$VAPI_API/assistant" \
  -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$JSON_FILE")

if [[ "$HTTP" != "200" && "$HTTP" != "201" ]]; then
  echo "    FAILED. HTTP $HTTP"
  echo "    Response body:"
  cat "$OUT_BODY"
  echo ""
  exit 1
fi

ES_ID=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('id',''))" "$OUT_BODY")

if [[ -z "$ES_ID" ]]; then
  echo "    HTTP $HTTP but no id in response. Body:"
  cat "$OUT_BODY"
  exit 1
fi

echo "    OK. Spanish Assistant ID: $ES_ID"

# Save both IDs to .env (English ID was captured manually from prior run)
EN_ID="87fe3aca-0c9a-4671-b744-398145e531dd"

{
  grep -v '^VAPI_ENGLISH_ASSISTANT_ID=' "$ENV_FILE" 2>/dev/null \
    | grep -v '^VAPI_SPANISH_ASSISTANT_ID=' || true
  echo "VAPI_ENGLISH_ASSISTANT_ID=$EN_ID"
  echo "VAPI_SPANISH_ASSISTANT_ID=$ES_ID"
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
chmod 600 "$ENV_FILE"

cat <<EOF

============================================================
BOTH ASSISTANTS LIVE
============================================================

English Assistant: $EN_ID
Spanish Assistant: $ES_ID

Saved to .env. View them in Vapi:
  https://dashboard.vapi.ai/assistants

NEXT:
  1. Buy a phone number: https://dashboard.vapi.ai/phone-numbers
  2. Build the IVR Workflow: see guides/ivr_workflow_setup.md

EOF
