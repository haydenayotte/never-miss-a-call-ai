#!/usr/bin/env bash
# Updates the live IVR Workflow with the latest agent/ivr_workflow.json.
# PATCHes the existing workflow (does NOT create a new one), so your phone
# number stays pointed at the same workflow ID.
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-update-workflow.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# shellcheck disable=SC1090
source "$ENV_FILE"

for var in VAPI_PRIVATE_KEY VAPI_ENGLISH_ASSISTANT_ID VAPI_SPANISH_ASSISTANT_ID VAPI_WORKFLOW_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: $var not set in .env"; exit 1
  fi
done

VAPI_API="https://api.vapi.ai"
TEMPLATE="$PROJECT_ROOT/agent/ivr_workflow.json"
PAYLOAD="/tmp/vapi_workflow_patch.json"
OUT_BODY="/tmp/vapi_workflow_response.json"

# Substitute placeholders and send the full template as the PATCH body.
python3 <<PY
import json
data = json.load(open("$TEMPLATE"))
text = json.dumps(data)
text = text.replace("__ENGLISH_ASSISTANT_ID__", "$VAPI_ENGLISH_ASSISTANT_ID")
text = text.replace("__SPANISH_ASSISTANT_ID__", "$VAPI_SPANISH_ASSISTANT_ID")
patched = json.loads(text)
json.dump(patched, open("$PAYLOAD", "w"))
PY

echo "==> Patching workflow $VAPI_WORKFLOW_ID..."
HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X PATCH "$VAPI_API/workflow/$VAPI_WORKFLOW_ID" \
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

echo "    OK. Workflow updated."
echo ""
echo "Test now: call your Vapi number, press 1 or 2 after the greeting."
echo "View workflow: https://dashboard.vapi.ai/workflows/$VAPI_WORKFLOW_ID"
