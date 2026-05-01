# Lead Pipeline Setup — End to End

This is the master guide for wiring up the lead delivery pipeline:

```
Vapi (call ends) → n8n webhook → Google Sheets + Notion + Google Calendar + Twilio SMS
```

Estimated time: **45-60 minutes** end-to-end.

---

## Phase 1 — Prep (15 min)

You'll gather credentials and create the destination accounts before touching n8n.

### 1.1 — Create the Google Sheet

1. Go to https://sheets.new
2. Rename the sheet to **"Techo Buddy — Leads"**.
3. Rename the first tab (bottom) to **"Leads"** (exactly).
4. Open `automation/lead-master-template.csv` from this project, copy the header row, and paste it into row 1 of the sheet.
5. Save the **Sheet ID** to `.env`. You can find it in the URL:
   ```
   https://docs.google.com/spreadsheets/d/<SHEET_ID>/edit
   ```
   Add to `.env`:
   ```
   GOOGLE_SHEET_ID=<paste here>
   ```

### 1.2 — Create the Notion Database

Follow `automation/notion-database-schema.md` step-by-step. By the end you should have these in `.env`:

```
NOTION_TOKEN=secret_...
NOTION_DATABASE_ID=...
```

### 1.3 — Get your Google Calendar ID

1. Open Google Calendar → top-left, find the calendar you want inspections to land on (usually your primary).
2. Hover over it → click `⋮` → **Settings and sharing** → scroll to **Integrate calendar** → copy **Calendar ID** (looks like `you@gmail.com` or `abc123@group.calendar.google.com`).
3. Add to `.env`:
   ```
   GOOGLE_CALENDAR_ID=you@gmail.com
   ```

### 1.4 — Twilio credentials

1. Log into https://console.twilio.com
2. Top of dashboard: copy **Account SID** and **Auth Token**.
3. Find your Twilio phone number (Phone Numbers → Active Numbers).
4. Add to `.env`:
   ```
   TWILIO_ACCOUNT_SID=AC...
   TWILIO_AUTH_TOKEN=...
   TWILIO_FROM_NUMBER=+15551234567
   OWNER_PHONE_NUMBER=+15559876543
   ```
   `OWNER_PHONE_NUMBER` is where lead-alert SMS messages go.

---

## Phase 2 — Build the n8n workflow (15 min)

### 2.1 — Import the workflow

1. Open your n8n instance (cloud or self-hosted).
2. Click **+ Add workflow** → top-right `⋯` menu → **Import from File**.
3. Select `automation/n8n-workflow.json` from this project.
4. The "Techo Buddy — Lead Pipeline" workflow loads with all nodes wired up.

### 2.2 — Set environment variables in n8n

n8n cloud users: **Settings → Variables**. Self-hosted: edit `.env` of your n8n container.

Set these (same values as your project `.env`):

| Variable | Value |
|---|---|
| `GOOGLE_SHEET_ID` | from step 1.1 |
| `NOTION_DATABASE_ID` | from step 1.2 |
| `GOOGLE_CALENDAR_ID` | from step 1.3 |
| `TWILIO_FROM_NUMBER` | from step 1.4 |
| `OWNER_PHONE_NUMBER` | from step 1.4 |

### 2.3 — Connect credentials

For each of the four destination nodes, click the node → **Credential to use** → **Create New**:

- **Google Sheets — Append Lead**: OAuth2, sign in with the Google account that owns the Sheet. Make sure to share the sheet with that account.
- **Notion — Create Lead**: paste your `NOTION_TOKEN` (Internal Integration Secret).
- **Google Calendar — Create Inspection**: OAuth2, sign in with the Google account that owns the calendar.
- **Twilio — SMS to Owner**: paste `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN`.

### 2.4 — Activate the workflow

Top-right of the n8n editor: toggle **Active** to ON. n8n will give you the production webhook URL — copy it. It looks like:

```
https://your-n8n.example.com/webhook/techo-buddy-leads
```

Add to your project `.env`:

```
N8N_WEBHOOK_URL=https://your-n8n.example.com/webhook/techo-buddy-leads
```

---

## Phase 3 — Wire Vapi to n8n (5 min)

### 3.1 — Push the updated assistant config + webhook URL to Vapi

```bash
cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
bash scripts/vapi-set-webhook.sh
```

This script PATCHes your live Bilingual Receptionist with two things:
- `analysisPlan` — Vapi will now extract structured lead data after every call
- `serverUrl` — Vapi will POST end-of-call reports to your n8n webhook

---

## Phase 4 — End-to-end test (10 min)

### 4.1 — Make a test call

Call your Vapi phone number. Run through a full conversation:

1. Greet in English (or Spanish — try one of each across two calls).
2. Say you have a 2,500 sqft home, want a roof replacement, asphalt shingles, active leak.
3. Provide your name, the address `123 Main St, Houston TX`.
4. Agree to a fake inspection time: **"Tomorrow at 10 AM"**.
5. Hang up.

### 4.2 — Check each destination within 30 seconds

| Destination | What you should see |
|---|---|
| **Google Sheet** | New row in the "Leads" tab with all fields populated |
| **Notion** | New page in the Leads database with status "New" |
| **Google Calendar** | New event "Roof Inspection — [Your Name]" tomorrow at 10 AM |
| **Owner's phone** | SMS within 10-15 seconds with the lead summary |

### 4.3 — If something didn't fire

Open your n8n workflow → click the most recent **Execution** (left sidebar) → look for the red node. The error tells you which credential / mapping is off.

Common issues:
- **Sheets append failed**: the column header in the sheet doesn't match the n8n mapping (must match exactly, case-sensitive).
- **Notion property error**: a Select option doesn't exist (e.g., n8n tried to set `Lead Quality = Hot` but you only have `hot` lowercase).
- **Twilio "21211" error**: phone number isn't E.164 format (must include `+1` prefix).
- **GCal "invalid time" error**: `appointment_datetime` from Vapi isn't ISO 8601. Check the assistant's analysisPlan output in Vapi → Calls → recent call → Analysis tab.

---

## Phase 5 — Production hygiene (5 min)

### 5.1 — Lock down the webhook

Vapi signs requests with `serverUrlSecret`. In n8n, edit the **Vapi Webhook** node → **Authentication** → **Header Auth** → header name `X-Vapi-Secret`, value = your `N8N_WEBHOOK_SECRET` from `.env`. Now random POST requests to your webhook are rejected.

### 5.2 — Rotate the Vapi key

You've been pasting your Vapi private key into chat for a while. Go to Vapi → API Keys → delete the old one and create a fresh one. Update `.env`. (Your existing assistants/workflows keep working — keys auth API access, not resources.)

### 5.3 — Tidy up

Optional cleanup if you want a clean account:
- Delete the failed `Techo Buddy - Language Router` workflow in Vapi → Workflows.
- Delete the unused Spanish-only assistant if you're committed to single-bilingual. (Or keep it as a fallback — costs nothing while idle.)

---

## What you have at the end of this

```
                ┌── Google Sheet (Lead Master) ──┐
                │                                │
Vapi call ──→ n8n ──→ Notion (Kanban CRM)        ├──→ You + roofing client
                │                                │
                ├── Twilio SMS (instant alert) ──┤
                │                                │
                └── Google Calendar (booking) ───┘
```

Every call generates a structured lead, alerts the owner via SMS, and (if booked) creates a calendar event automatically. This is the demo you show to roofing contractors — when they see a lead arrive in their Sheet/Notion + a calendar event + a text within 15 seconds of a fake call, they sign up.
