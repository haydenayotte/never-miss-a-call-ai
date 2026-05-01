#!/usr/bin/env bash
# Creates the "Techo Buddy Leads" database in Notion via the Notion API.
# Adds all 20 properties with the right types and dropdown options.
# Saves NOTION_DATABASE_ID to .env on success.
#
# PREREQUISITES (one-time, manual — see guides/notion-prep.md):
#   1. Create an Internal Integration at https://www.notion.so/my-integrations
#      Copy the secret → put in .env as NOTION_TOKEN
#   2. Create a parent page in Notion (e.g., "Techo Buddy")
#   3. Share that page with your integration: top-right ••• → Connections → Add
#   4. Copy the parent page ID from the URL → put in .env as NOTION_PARENT_PAGE_ID
#
# USAGE:
#   cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
#   bash scripts/notion-create-database.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env not found at $ENV_FILE"; exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${NOTION_TOKEN:-}" ]]; then
  echo "ERROR: NOTION_TOKEN not set in .env"
  echo ""
  echo "Get one at https://www.notion.so/my-integrations"
  echo "Then add to .env:"
  echo "  NOTION_TOKEN=secret_..."
  exit 1
fi

if [[ -z "${NOTION_PARENT_PAGE_ID:-}" ]]; then
  echo "ERROR: NOTION_PARENT_PAGE_ID not set in .env"
  echo ""
  echo "1. Create a parent page in Notion (e.g., 'Techo Buddy')"
  echo "2. Share it with your integration: ••• → Connections → Add"
  echo "3. Copy the 32-char ID from the page URL"
  echo "4. Add to .env:"
  echo "   NOTION_PARENT_PAGE_ID=abc123..."
  exit 1
fi

# Strip dashes from page ID if present (Notion accepts both formats but cleaner without)
PARENT_ID=$(echo "$NOTION_PARENT_PAGE_ID" | tr -d '-')

PAYLOAD="/tmp/notion_create_db_payload.json"
OUT_BODY="/tmp/notion_create_db_response.json"

# Build the request body
cat > "$PAYLOAD" <<'JSON'
{
  "parent": {"type": "page_id", "page_id": "__PARENT_ID__"},
  "icon": {"type": "emoji", "emoji": "🏠"},
  "title": [{"type": "text", "text": {"content": "Leads"}}],
  "properties": {
    "Lead Name": {"title": {}},
    "Status": {
      "select": {
        "options": [
          {"name": "New", "color": "blue"},
          {"name": "Contacted", "color": "yellow"},
          {"name": "Booked", "color": "purple"},
          {"name": "Inspected", "color": "orange"},
          {"name": "Won", "color": "green"},
          {"name": "Lost", "color": "red"}
        ]
      }
    },
    "Phone": {"phone_number": {}},
    "Language": {
      "select": {
        "options": [
          {"name": "English", "color": "blue"},
          {"name": "Spanish", "color": "orange"}
        ]
      }
    },
    "Service Type": {
      "select": {
        "options": [
          {"name": "Repair", "color": "yellow"},
          {"name": "Replacement", "color": "purple"},
          {"name": "Inspection Only", "color": "gray"},
          {"name": "Unknown", "color": "default"}
        ]
      }
    },
    "Address": {"rich_text": {}},
    "Roof Size (sqft)": {"number": {"format": "number"}},
    "Material": {
      "select": {
        "options": [
          {"name": "Standard", "color": "gray"},
          {"name": "Premium", "color": "purple"},
          {"name": "Unknown", "color": "default"}
        ]
      }
    },
    "Quote Low": {"number": {"format": "dollar"}},
    "Quote High": {"number": {"format": "dollar"}},
    "Urgency": {
      "select": {
        "options": [
          {"name": "Active Leak", "color": "red"},
          {"name": "This Week", "color": "orange"},
          {"name": "This Month", "color": "yellow"},
          {"name": "Planning", "color": "blue"},
          {"name": "Unknown", "color": "default"}
        ]
      }
    },
    "Insurance Claim": {"checkbox": {}},
    "Appointment Booked": {"checkbox": {}},
    "Appointment": {"date": {}},
    "Lead Quality": {
      "select": {
        "options": [
          {"name": "Hot", "color": "red"},
          {"name": "Warm", "color": "orange"},
          {"name": "Cold", "color": "blue"}
        ]
      }
    },
    "Follow-up Notes": {"rich_text": {}},
    "Summary": {"rich_text": {}},
    "Recording": {"url": {}},
    "Call ID": {"rich_text": {}}
  }
}
JSON

# Substitute the parent page ID
sed -i.bak "s|__PARENT_ID__|$PARENT_ID|g" "$PAYLOAD" && rm -f "$PAYLOAD.bak"

# Validate JSON
if ! python3 -c "import json; json.load(open('$PAYLOAD'))" 2>/dev/null; then
  echo "ERROR: Built payload is invalid JSON. This is a script bug."
  cat "$PAYLOAD"
  exit 1
fi

echo "==> Creating Notion database under parent page $PARENT_ID..."

HTTP=$(curl -s -o "$OUT_BODY" -w "%{http_code}" \
  -X POST "https://api.notion.com/v1/databases" \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  --data-binary "@$PAYLOAD")

if [[ "$HTTP" != "200" ]]; then
  echo "    FAILED. HTTP $HTTP"
  echo "    Response body:"
  cat "$OUT_BODY" | python3 -m json.tool 2>/dev/null || cat "$OUT_BODY"
  echo ""
  echo "    Common causes:"
  echo "      - NOTION_TOKEN is invalid or expired"
  echo "      - The parent page hasn't been shared with the integration"
  echo "        (Open the page → top right ••• → Connections → Add → select your integration)"
  echo "      - NOTION_PARENT_PAGE_ID is wrong (must be the 32-char ID, with or without dashes)"
  exit 1
fi

DB_ID=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('id',''))" "$OUT_BODY" | tr -d '-')
DB_URL=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('url',''))" "$OUT_BODY")

if [[ -z "$DB_ID" ]]; then
  echo "    HTTP 200 but no database ID in response. Raw response:"
  cat "$OUT_BODY"
  exit 1
fi

echo "    OK. Database created."
echo "    ID:  $DB_ID"
echo "    URL: $DB_URL"
echo ""

# Save to .env
{
  grep -v '^NOTION_DATABASE_ID=' "$ENV_FILE" 2>/dev/null || true
  echo "NOTION_DATABASE_ID=$DB_ID"
} > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
chmod 600 "$ENV_FILE"

cat <<EOF
============================================================
NOTION DATABASE READY
============================================================

Open it: $DB_URL

Saved to .env:
  NOTION_DATABASE_ID=$DB_ID

NEXT (in Notion UI, ~30 sec):
  Convert default view to a Board to make it look like a CRM:
    1. Open the database.
    2. Click "+ Add a view" (top of the database).
    3. Choose "Board".
    4. Group by: Status.
    5. Drag column order: New, Contacted, Booked, Inspected, Won, Lost.

Then continue with Phase 1.3 in guides/lead-pipeline-setup.md.

EOF
