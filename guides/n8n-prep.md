# n8n Prep — 2 Minutes Before Running the Deploy Script

Two values needed to give the script API access to your n8n instance.

## Step 1 — Get your n8n Base URL

This is the homepage URL of your n8n instance, **without trailing slash**:

- **n8n cloud**: `https://yourname.app.n8n.cloud` (find it in your browser address bar)
- **Self-hosted**: whatever URL you set up (e.g., `https://n8n.yourdomain.com`)

Add to `.env`:
```
N8N_BASE_URL=https://yourname.app.n8n.cloud
```

## Step 2 — Generate an n8n API Key

1. Open your n8n instance.
2. Click your **profile icon** (bottom-left corner) → **Settings**.
3. Left sidebar: **API**.
4. Click **+ Create API Key**.
5. Label: `Techo Buddy Deploy`. Expiration: **No expiration** (for now; rotate later).
6. Click **Save** → **Copy** the key immediately (it shows only once).
7. Add to `.env`:
   ```
   N8N_API_KEY=n8n_api_...
   ```

## Step 3 — Run the Deploy Script

```bash
cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
python3 scripts/n8n-deploy.py
```

The script will:
- Test API connectivity
- Import `automation/n8n-workflow.json`
- Create Notion + Twilio credentials and wire them into the workflow nodes
- Activate the workflow
- Print the production webhook URL and save it to `.env` as `N8N_WEBHOOK_URL`

## Step 4 — The 2 Manual Things Left

Open n8n → click your imported "Techo Buddy — Lead Pipeline" workflow:

1. Click the **Google Sheets — Append Lead** node:
   - Click the **Credential** dropdown → **+ Create New Credential**
   - Choose **Google Sheets OAuth2 API**
   - Click **Sign in with Google**, allow access, save

2. Click the **Google Calendar — Create Inspection** node:
   - Same flow, but choose **Google Calendar OAuth2 API**
   - Sign in with the same Google account, allow, save

3. Click **Save** (top-right) on the workflow. Done.

## Troubleshooting

| Error | Fix |
|---|---|
| `401 Unauthorized` from n8n | API key is wrong or expired. Regenerate. |
| `404 Not Found` on /api/v1/workflows | Old n8n version. Self-hosted instances < v0.220 may have different paths. Update n8n. |
| `Variables endpoint not available` | Your n8n plan doesn't include Variables. Script will fall back to printing them — paste manually into the workflow's "Settings → Variables" page. |
| Workflow imports but doesn't activate | Open it in UI and click Activate yourself. Probably a credential reference issue. |
