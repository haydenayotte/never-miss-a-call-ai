#!/usr/bin/env bash
# Vapi Setup Script for Techo Buddy
# Creates English + Spanish receptionist assistants in your Vapi account.
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/vapi-setup.sh

# NOTE: We deliberately do NOT use `set -e` so that we can show full error
# responses from Vapi rather than exiting silently on grep no-matches.
set -uo pipefail

# --- Locate project root and load API key ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found at $ENV_FILE"
  echo "Create one with: VAPI_PRIVATE_KEY=your-key-here"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${VAPI_PRIVATE_KEY:-}" ]]; then
  echo "ERROR: VAPI_PRIVATE_KEY not set in $ENV_FILE"
  exit 1
fi

VAPI_API="https://api.vapi.ai"
AGENT_DIR="$PROJECT_ROOT/agent"

# --- Step 0: Sanity check the API key ---
echo "==> Checking API key..."
SANITY_HTTP=$(curl -s -o /tmp/vapi_sanity.json -w "%{http_code}" \
  -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
  "$VAPI_API/assistant?limit=1")

if [[ "$SANITY_HTTP" != "200" ]]; then
  echo "    FAILED. HTTP $SANITY_HTTP"
  echo "    Response body:"
  cat /tmp/vapi_sanity.json
  echo ""
  echo "    Common causes:"
  echo "      - Wrong key (using public key instead of private)"
  echo "      - Key was rotated/deleted in the Vapi dashboard"
  echo "      - 'Authorization' header malformed (check for stray quotes/spaces in .env)"
  exit 1
fi
echo "    OK (HTTP 200)"

# --- Helper: POST a JSON file and print response with HTTP code ---
post_assistant () {
  local label="$1"
  local json_file="$2"
  local out_body="/tmp/vapi_${label}_body.json"

  local http
  http=$(curl -s -o "$out_body" -w "%{http_code}" \
    -X POST "$VAPI_API/assistant" \
    -H "Authorization: Bearer $VAPI_PRIVATE_KEY" \
    -H "Content-Type: application/json" \
    --data-binary "@$json_file")

  echo "$http"
}

extract_id_from_file () {
  python3 -c "
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get('id', ''))
except Exception as e:
    sys.stderr.write(f'parse error: {e}\n')
    sys.exit(1)
" "$1"
}

create_assistant () {
  local label="$1"
  local json_file="$2"
  local out_body="/tmp/vapi_${label}_body.json"

  echo "==> Creating ${label} Assistant..."
  local http
  http=$(post_assistant "$label" "$json_file")

  if [[ "$http" != "200" && "$http" != "201" ]]; then
    echo "    FAILED. HTTP $http"
    echo "    Response body:"
    cat "$out_body"
    echo ""
    return 1
  fi

  local id
  id=$(extract_id_from_file "$out_body")
  if [[ -z "$id" ]]; then
    echo "    HTTP $http but no 'id' in response. Body:"
    cat "$out_body"
    echo ""
    return 1
  fi

  echo "    OK. ${label} Assistant ID: $id"
  echo "$id"
}

# --- Step 1: Create English Assistant ---
EN_OUTPUT=$(create_assistant "English" "$AGENT_DIR/english_assistant.json")
EN_STATUS=$?
EN_ID=$(echo "$EN_OUTPUT" | tail -1)
echo "$EN_OUTPUT"
[[ $EN_STATUS -ne 0 ]] && exit 1

# --- Step 2: Create Spanish Assistant ---
ES_OUTPUT=$(create_assistant "Spanish" "$AGENT_DIR/spanish_assistant.json")
ES_STATUS=$?
ES_ID=$(echo "$ES_OUTPUT" | tail -1)
echo "$ES_OUTPUT"
[[ $ES_STATUS -ne 0 ]] && exit 1

# --- Step 3: Save IDs to .env ---
echo "==> Saving assistant IDs to .env..."
{
  grep -v '^VAPI_ENGLISH_ASSISTANT_ID=' "$ENV_FILE" 2>/dev/null \
    | grep -v '^VAPI_SPANISH_ASSISTANT_ID=' || true
  echo "VAPI_ENGLISH_ASSISTANT_ID=$EN_ID"
  echo "VAPI_SPANISH_ASSISTANT_ID=$ES_ID"
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
chmod 600 "$ENV_FILE"

# --- Step 4: List phone numbers ---
echo ""
echo "==> Phone numbers on your Vapi account:"
PHONE_RESPONSE=$(curl -s -H "Authorization: Bearer $VAPI_PRIVATE_KEY" "$VAPI_API/phone-number")
if [[ "$PHONE_RESPONSE" == "[]" || -z "$PHONE_RESPONSE" ]]; then
  echo "    (none yet — buy one at https://dashboard.vapi.ai/phone-numbers)"
else
  echo "$PHONE_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if not data:
        print('    (none)')
    for p in data:
        print(f\"    {p.get('number', '?')}  →  id: {p.get('id', '?')}\")
except Exception:
    print(sys.stdin.read())
"
fi

cat <<EOF

============================================================
SETUP COMPLETE
============================================================

English Assistant: $EN_ID
Spanish Assistant: $ES_ID

Both assistants are now live: https://dashboard.vapi.ai/assistants

NEXT STEPS:
  1. Buy a phone number in Vapi → Phone Numbers → Buy.
  2. Build the IVR Workflow. See: guides/ivr_workflow_setup.md
  3. Point the phone number at the Workflow and test.

EOF
