#!/usr/bin/env bash
# Pushes the full bilingual config to the live English Assistant.
# This converts it from "English-only" to "Bilingual Receptionist" by PATCHing
# name, firstMessage, model (with system prompt + tools), voice, and transcriber.
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-update-bilingual.sh

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
OUT_BODY="/tmp/vapi_bilingual_response.json"

echo "==> Pushing bilingual config to assistant $VAPI_ENGLISH_ASSISTANT_ID..."

HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X PATCH "$VAPI_API/assistant/$VAPI_ENGLISH_ASSISTANT_ID" \
  -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$JSON_FILE")

if [[ "$HTTP" != "200" ]]; then
  echo "    FAILED. HTTP $HTTP"
  echo "    Response body:"
  cat "$OUT_BODY" | python3 -m json.tool 2>/dev/null || cat "$OUT_BODY"
  echo ""
  exit 1
fi

echo "    OK. Assistant updated."
echo ""
echo "============================================================"
echo "BILINGUAL ASSISTANT LIVE"
echo "============================================================"
echo ""
echo "Assistant: https://dashboard.vapi.ai/assistants/$VAPI_ENGLISH_ASSISTANT_ID"
echo ""
echo "NEXT (in Vapi UI, ~30 seconds):"
echo "  1. Go to https://dashboard.vapi.ai/phone-number"
echo "  2. Click your phone number."
echo "  3. Under 'Inbound Settings', change destination from"
echo "     the workflow to: Techo Buddy - Bilingual Receptionist"
echo "  4. Save."
echo ""
echo "Then call the number and test in both languages."
