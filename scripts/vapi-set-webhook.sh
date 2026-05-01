#!/usr/bin/env bash
# Sets the Vapi assistant's serverUrl (webhook) to your n8n endpoint AND
# pushes the latest agent/english_assistant.json (with analysisPlan) to the
# live assistant.
#
# Reads N8N_WEBHOOK_URL from .env. Optionally reads N8N_WEBHOOK_SECRET for
# webhook signature verification (recommended for production).
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-set-webhook.sh

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

if [[ -z "${N8N_WEBHOOK_URL:-}" ]]; then
  echo "ERROR: N8N_WEBHOOK_URL not set in .env"
  echo ""
  echo "Add this line to .env (replace with your real n8n webhook URL):"
  echo '  N8N_WEBHOOK_URL=https://your-n8n.example.com/webhook/techo-buddy-leads'
  exit 1
fi

VAPI_API="https://api.vapi.ai"
JSON_FILE="$PROJECT_ROOT/agent/english_assistant.json"
PAYLOAD="/tmp/vapi_assistant_patch.json"
OUT_BODY="/tmp/vapi_webhook_response.json"

# Substitute placeholders in the assistant JSON
WEBHOOK_SECRET="${N8N_WEBHOOK_SECRET:-techo-buddy-${RANDOM}-secret}"

python3 <<PY
import json
data = json.load(open("$JSON_FILE"))
data["serverUrl"] = "$N8N_WEBHOOK_URL"
data["serverUrlSecret"] = "$WEBHOOK_SECRET"
json.dump(data, open("$PAYLOAD", "w"))
PY

echo "==> Pushing assistant config + webhook URL to Vapi..."
echo "    Assistant ID: $VAPI_ENGLISH_ASSISTANT_ID"
echo "    Webhook URL:  $N8N_WEBHOOK_URL"
echo ""

HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X PATCH "$VAPI_API/assistant/$VAPI_ENGLISH_ASSISTANT_ID" \
  -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$PAYLOAD")

if [[ "$HTTP" != "200" ]]; then
  echo "    FAILED. HTTP $HTTP"
  echo "    Response body:"
  cat "$OUT_BODY" | python3 -m json.tool 2>/dev/null || cat "$OUT_BODY"
  echo ""
  exit 1
fi

echo "    OK. Assistant updated with webhook + analysisPlan."

# Save the secret to .env if it was generated
if [[ -z "${N8N_WEBHOOK_SECRET:-}" ]]; then
  {
    grep -v '^N8N_WEBHOOK_SECRET=' "$ENV_FILE" 2>/dev/null || true
    echo "N8N_WEBHOOK_SECRET=$WEBHOOK_SECRET"
  } > "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "    Generated webhook secret saved to .env: N8N_WEBHOOK_SECRET=$WEBHOOK_SECRET"
fi

cat <<EOF

============================================================
WEBHOOK WIRED UP
============================================================

The assistant will now POST end-of-call reports to your n8n workflow.
Make sure your n8n workflow is ACTIVE (toggle in top-right of editor).

Webhook secret: $WEBHOOK_SECRET
  → use this in your n8n webhook node's "Authentication" → "Header Auth"
    if you want to verify Vapi requests are legit.

Test by calling your Vapi number, then check:
  - Google Sheet: new row appended
  - Notion: new page in the Leads database
  - Twilio: SMS to OWNER_PHONE_NUMBER
  - Google Calendar: event created (only if appointment was booked)

EOF
