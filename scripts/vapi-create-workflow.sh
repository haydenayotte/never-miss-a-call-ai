#!/usr/bin/env bash
# Creates the IVR (Press 1 / Press 2) Workflow in Vapi.
# Reads agent/ivr_workflow.json, substitutes the assistant IDs from .env,
# POSTs to /workflow, prints the result.
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-create-workflow.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${VAPI_PRIVATE_KEY:-}" ]]; then
  echo "ERROR: VAPI_PRIVATE_KEY not set in .env"; exit 1
fi
if [[ -z "${VAPI_ENGLISH_ASSISTANT_ID:-}" ]]; then
  echo "ERROR: VAPI_ENGLISH_ASSISTANT_ID not set in .env"; exit 1
fi
if [[ -z "${VAPI_SPANISH_ASSISTANT_ID:-}" ]]; then
  echo "ERROR: VAPI_SPANISH_ASSISTANT_ID not set in .env"; exit 1
fi

VAPI_API="https://api.vapi.ai"
TEMPLATE="$PROJECT_ROOT/agent/ivr_workflow.json"
PAYLOAD="/tmp/vapi_workflow_payload.json"
OUT_BODY="/tmp/vapi_workflow_response.json"

# Substitute placeholders with actual IDs
sed \
  -e "s|__ENGLISH_ASSISTANT_ID__|$VAPI_ENGLISH_ASSISTANT_ID|g" \
  -e "s|__SPANISH_ASSISTANT_ID__|$VAPI_SPANISH_ASSISTANT_ID|g" \
  "$TEMPLATE" > "$PAYLOAD"

# Validate JSON before sending
if ! python3 -c "import json; json.load(open('$PAYLOAD'))" 2>/dev/null; then
  echo "ERROR: Built payload is not valid JSON. Check agent/ivr_workflow.json"
  exit 1
fi

echo "==> Creating IVR Workflow..."
echo "    English Assistant: $VAPI_ENGLISH_ASSISTANT_ID"
echo "    Spanish Assistant: $VAPI_SPANISH_ASSISTANT_ID"
echo ""

HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X POST "$VAPI_API/workflow" \
  -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$PAYLOAD")

if [[ "$HTTP" != "200" && "$HTTP" != "201" ]]; then
  echo "    FAILED. HTTP $HTTP"
  echo "    Response body:"
  cat "$OUT_BODY" | python3 -m json.tool 2>/dev/null || cat "$OUT_BODY"
  echo ""
  echo "    The Workflows API schema can vary. Paste the response above"
  echo "    into chat and Claude will adjust agent/ivr_workflow.json."
  exit 1
fi

WORKFLOW_ID=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('id',''))" "$OUT_BODY")

if [[ -z "$WORKFLOW_ID" ]]; then
  echo "    HTTP $HTTP but no 'id' in response. Body:"
  cat "$OUT_BODY"
  exit 1
fi

echo "    OK. Workflow ID: $WORKFLOW_ID"

# Save workflow ID to .env
{
  grep -v '^VAPI_WORKFLOW_ID=' "$ENV_FILE" 2>/dev/null || true
  echo "VAPI_WORKFLOW_ID=$WORKFLOW_ID"
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
chmod 600 "$ENV_FILE"

cat <<EOF

============================================================
WORKFLOW CREATED
============================================================

Workflow ID: $WORKFLOW_ID
View it at:  https://dashboard.vapi.ai/workflows/$WORKFLOW_ID

NEXT:
  1. Buy a phone number (if you haven't):
     https://dashboard.vapi.ai/phone-numbers
  2. In Phone Numbers, set the inbound destination to this Workflow
     (instead of an Assistant).
  3. Call the number and run the four tests in
     guides/ivr_workflow_setup.md (the test table near the bottom).

EOF
