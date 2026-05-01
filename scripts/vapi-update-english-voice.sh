#!/usr/bin/env bash
# Updates the voice on the live English Assistant.
# Reads the current voice block from agent/english_assistant.json and PATCHes it.
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-update-english-voice.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${VAPI_PRIVATE_KEY:-}" ]] || [[ -z "${VAPI_ENGLISH_ASSISTANT_ID:-}" ]]; then
  echo "ERROR: VAPI_PRIVATE_KEY and VAPI_ENGLISH_ASSISTANT_ID must be set in .env"
  exit 1
fi

VAPI_API="https://api.vapi.ai"
JSON_FILE="$PROJECT_ROOT/agent/english_assistant.json"
PATCH_BODY="/tmp/vapi_voice_patch.json"
OUT_BODY="/tmp/vapi_update_body.json"

# Extract just the voice block from the JSON
python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
patch = {'voice': data['voice']}
json.dump(patch, open(sys.argv[2], 'w'))
" "$JSON_FILE" "$PATCH_BODY"

echo "==> Pushing new voice config to English Assistant ($VAPI_ENGLISH_ASSISTANT_ID)..."
cat "$PATCH_BODY"
echo ""

HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X PATCH "$VAPI_API/assistant/$VAPI_ENGLISH_ASSISTANT_ID" \
  -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$PATCH_BODY")

if [[ "$HTTP" != "200" ]]; then
  echo "    FAILED. HTTP $HTTP"
  echo "    Response body:"
  cat "$OUT_BODY"
  echo ""
  exit 1
fi

echo "    OK. English Assistant voice updated."
echo ""
echo "Test it now: https://dashboard.vapi.ai/assistants/$VAPI_ENGLISH_ASSISTANT_ID"
echo "Click 'Talk' to hear the new voice."
