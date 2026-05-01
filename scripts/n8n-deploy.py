#!/usr/bin/env python3
"""
Phase 2 deploy: imports the Techo Buddy lead pipeline workflow into your n8n
instance, creates non-OAuth credentials (Notion + Twilio), wires them into
the workflow nodes, and activates the workflow.

Things this script CANNOT do (browser-only):
- Google Sheets OAuth (you'll do this in n8n UI: 2 clicks)
- Google Calendar OAuth (same: 2 clicks)

PREREQUISITES (in .env):
  N8N_BASE_URL=https://yourname.app.n8n.cloud
  N8N_API_KEY=n8n_api_...
  NOTION_TOKEN=ntn_...
  TWILIO_ACCOUNT_SID=AC...
  TWILIO_AUTH_TOKEN=...        (or)
  TWILIO_API_KEY_SID=SK...     (alternative pair)
  TWILIO_API_KEY_SECRET=...

USAGE:
  cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
  python3 scripts/n8n-deploy.py
"""

import json
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
ENV_FILE = PROJECT_ROOT / ".env"
WORKFLOW_FILE = PROJECT_ROOT / "automation" / "n8n-workflow.json"


def load_env():
    if not ENV_FILE.exists():
        sys.exit(f"ERROR: .env not found at {ENV_FILE}")
    env = {}
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip()
    return env


def save_env(updates):
    """Merge updates into .env, preserving existing keys not in updates."""
    existing = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                k, _, v = line.partition("=")
                existing[k.strip()] = v.strip()
    existing.update(updates)
    body = "\n".join(f"{k}={v}" for k, v in existing.items()) + "\n"
    ENV_FILE.write_text(body)
    os.chmod(ENV_FILE, 0o600)


env = load_env()
N8N_BASE = env.get("N8N_BASE_URL", "").rstrip("/")
N8N_KEY = env.get("N8N_API_KEY", "")

if not N8N_BASE:
    sys.exit("ERROR: N8N_BASE_URL not set in .env. See guides/n8n-prep.md.")
if not N8N_KEY:
    sys.exit("ERROR: N8N_API_KEY not set in .env. See guides/n8n-prep.md.")


def n8n(method, endpoint, body=None):
    url = f"{N8N_BASE}/api/v1/{endpoint.lstrip('/')}"
    headers = {
        "X-N8N-API-KEY": N8N_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            text = resp.read().decode("utf-8") or "{}"
            return resp.status, json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        try:
            return e.code, json.loads(body)
        except json.JSONDecodeError:
            return e.code, {"raw": body}
    except urllib.error.URLError as e:
        sys.exit(f"Network error reaching {url}: {e}")


def main():
    # ---- Step 1: ping n8n to verify auth ----
    print(f"==> Checking n8n at {N8N_BASE}...")
    code, _ = n8n("GET", "workflows?limit=1")
    if code == 401:
        sys.exit("    FAILED: 401 Unauthorized. Check your N8N_API_KEY.")
    if code == 404:
        sys.exit("    FAILED: 404. Either your n8n version is too old, or the base URL is wrong.")
    if code != 200:
        sys.exit(f"    FAILED: HTTP {code}. Cannot continue.")
    print("    OK")

    # ---- Step 2: load workflow JSON, strip placeholders ----
    if not WORKFLOW_FILE.exists():
        sys.exit(f"ERROR: workflow file not found: {WORKFLOW_FILE}")
    workflow = json.loads(WORKFLOW_FILE.read_text())

    # Remove fields the API rejects on create
    for k in ("active", "versionId", "triggerCount", "tags", "id", "pinData"):
        workflow.pop(k, None)

    # ---- Step 3: create Notion credential ----
    print("==> Creating Notion credential...")
    notion_token = env.get("NOTION_TOKEN", "")
    notion_cred_id = None
    if not notion_token:
        print("    SKIPPED: NOTION_TOKEN not set in .env")
    else:
        code, resp = n8n("POST", "credentials", {
            "name": "Techo Buddy Notion",
            "type": "notionApi",
            "data": {"apiKey": notion_token}
        })
        if code in (200, 201):
            notion_cred_id = resp.get("id")
            print(f"    OK. Credential ID: {notion_cred_id}")
        else:
            print(f"    WARN: HTTP {code}: {resp}. You'll need to create this credential manually in n8n.")

    # ---- Step 4: create Twilio credential ----
    print("==> Creating Twilio credential...")
    sid = env.get("TWILIO_ACCOUNT_SID", "")
    auth_token = env.get("TWILIO_AUTH_TOKEN", "")
    api_key_sid = env.get("TWILIO_API_KEY_SID", "")
    api_key_secret = env.get("TWILIO_API_KEY_SECRET", "")
    twilio_cred_id = None

    if sid and auth_token:
        # Use Auth Token auth
        cred_data = {
            "accountSid": sid,
            "authType": "authToken",
            "authToken": auth_token,
        }
    elif sid and api_key_sid and api_key_secret:
        # Use API Key auth
        cred_data = {
            "accountSid": sid,
            "authType": "apiKey",
            "apiKeySid": api_key_sid,
            "apiKeySecret": api_key_secret,
        }
    else:
        print("    SKIPPED: Twilio credentials not fully set in .env")
        cred_data = None

    if cred_data:
        code, resp = n8n("POST", "credentials", {
            "name": "Techo Buddy Twilio",
            "type": "twilioApi",
            "data": cred_data,
        })
        if code in (200, 201):
            twilio_cred_id = resp.get("id")
            print(f"    OK. Credential ID: {twilio_cred_id}")
        else:
            print(f"    WARN: HTTP {code}: {resp}. You'll need to create this credential manually.")

    # ---- Step 5: wire credentials into workflow nodes ----
    for node in workflow.get("nodes", []):
        if node.get("name") == "Notion — Create Lead" and notion_cred_id:
            node.setdefault("credentials", {})["notionApi"] = {
                "id": notion_cred_id, "name": "Techo Buddy Notion"
            }
        if node.get("name") == "Twilio — SMS to Owner" and twilio_cred_id:
            node.setdefault("credentials", {})["twilioApi"] = {
                "id": twilio_cred_id, "name": "Techo Buddy Twilio"
            }

    # ---- Step 6: import the workflow ----
    print("==> Importing workflow...")
    code, resp = n8n("POST", "workflows", workflow)
    if code not in (200, 201):
        sys.exit(f"    FAILED: HTTP {code}: {resp}")
    workflow_id = resp.get("id")
    print(f"    OK. Workflow ID: {workflow_id}")

    # ---- Step 7: activate ----
    print("==> Activating workflow...")
    code, resp = n8n("POST", f"workflows/{workflow_id}/activate")
    if code in (200, 201):
        print("    OK. Active.")
    else:
        # Some n8n versions use PATCH /workflows/:id with {active: true}
        code, resp = n8n("PATCH", f"workflows/{workflow_id}", {"active": True})
        if code in (200, 201):
            print("    OK. Active (via PATCH).")
        else:
            print(f"    WARN: Could not activate via API ({code}). Open the workflow in n8n UI and toggle Active.")

    # ---- Step 8: derive webhook URL ----
    webhook_path = "techo-buddy-leads"
    webhook_url = f"{N8N_BASE}/webhook/{webhook_path}"
    print(f"==> Webhook URL: {webhook_url}")

    save_env({
        "N8N_WORKFLOW_ID": workflow_id,
        "N8N_WEBHOOK_URL": webhook_url,
    })
    print("    Saved N8N_WORKFLOW_ID and N8N_WEBHOOK_URL to .env")

    # ---- Step 9: print remaining manual steps ----
    print("""
============================================================
PHASE 2 — 70% AUTOMATED. 2 MANUAL STEPS LEFT.
============================================================

Open the imported workflow in n8n. Two nodes need Google OAuth
that the API can't do for you (Google requires a browser):

  1. Click "Google Sheets — Append Lead" node
     → Credential dropdown → + Create New
     → Google Sheets OAuth2 API → Sign in with Google → save

  2. Click "Google Calendar — Create Inspection" node
     → Credential dropdown → + Create New
     → Google Calendar OAuth2 API → Sign in (same Google account) → save

Then click Save on the workflow.

NEXT (Phase 3): wire Vapi to your new n8n webhook URL:
    bash scripts/vapi-set-webhook.sh
""")


if __name__ == "__main__":
    main()
