# Google Apps Script Setup — No Google Cloud Required

Skip Google Cloud Console entirely. This approach uses Google Apps Script, which runs as YOU on Google's servers with full access to your Sheets and Calendar.

Setup time: **5 minutes.**

## Step 1 — Create the Apps Script

1. Go to **https://script.google.com**
2. Click **+ New project** (top-left)
3. Delete the placeholder `function myFunction()` code at the top
4. Open `automation/google-apps-script.gs` from this project, copy the entire file, paste into the editor
5. At the top of the script, replace these two lines:
   ```js
   const SHEET_ID    = 'YOUR_GOOGLE_SHEET_ID';
   const CALENDAR_ID = 'primary';
   ```
   With your actual values. Use `primary` for `CALENDAR_ID` if you want events to land on your default Google Calendar — otherwise paste a specific Calendar ID.
6. Click the **Save** icon (or `Cmd+S`). Name the project: `Techo Buddy Lead Pipeline`.

## Step 2 — Test the script (optional but recommended)

1. In the function dropdown at the top of the editor (next to the Run button), select `testWithSampleData`
2. Click **Run**
3. First run: Google will ask for permissions → **Review permissions** → pick your account → "Google hasn't verified this app" → **Advanced** → **Go to Techo Buddy Lead Pipeline (unsafe)** → **Allow**
4. Wait a few seconds. Then check:
   - Your Google Sheet should have a new test row
   - Your Calendar should have a "Roof Inspection — Test Hayden" event tomorrow

If both show up, the script works. If not, check the Execution log (View → Executions in left sidebar) for error details.

## Step 3 — Deploy as a Web App

1. Top-right: click **Deploy** → **New deployment**
2. Click the gear icon next to "Select type" → choose **Web app**
3. Configure:
   - **Description**: `Techo Buddy v1`
   - **Execute as**: **Me** (this is what gives the script access to your Sheets/Calendar)
   - **Who has access**: **Anyone** (the URL is the only secret; no one can guess it)
4. Click **Deploy**
5. **Copy the Web app URL**. Looks like:
   ```
   https://script.google.com/macros/s/AKfyc.../exec
   ```
6. Save it to `.env`:
   ```
   GOOGLE_APPS_SCRIPT_URL=https://script.google.com/macros/s/AKfyc.../exec
   ```

## Step 4 — Update n8n Workflow

In n8n, open your "Techo Buddy — Lead Pipeline" workflow and swap the two Google nodes for one HTTP Request node.

### 4a. Delete the old Google nodes

1. Click the **Google Sheets — Append Lead** node → press Delete (keyboard) or right-click → Delete
2. Click the **Google Calendar — Create Inspection** node → Delete
3. Click the **If Appointment Booked** node → Delete (no longer needed; Apps Script handles the conditional internally)

### 4b. Add an HTTP Request node

1. Click the **+** at the end of the **Parse Lead** node (or drag a new connection from Parse Lead)
2. Search for **HTTP Request** → click to add
3. Configure:
   - **Method**: `POST`
   - **URL**: `={{ $env.GOOGLE_APPS_SCRIPT_URL }}` (or paste the URL directly)
   - **Authentication**: `None`
   - **Send Body**: `Yes`
   - **Body Content Type**: `JSON`
   - **Specify Body**: `Using JSON`
   - **JSON**: `={{ JSON.stringify($json) }}`
4. Rename the node to: **Google — Sheet + Calendar**
5. Connect output → **Respond OK** node

### 4c. Save the workflow

Click **Save** (top-right of the editor).

### 4d. Add the env variable in n8n

In n8n: **Settings** (your profile, bottom-left) → **Variables** → **+ Add Variable**:
- **Key**: `GOOGLE_APPS_SCRIPT_URL`
- **Value**: paste the same URL from Step 3.6

(If your n8n plan doesn't include Variables, just paste the URL directly into the HTTP Request node's URL field.)

## Done

Test it: in n8n, click the workflow name → **Execute Workflow** → choose **Listen for Test Event** → call your Vapi number from your phone → after the call, the workflow runs end-to-end. New row in Sheet + new Calendar event should appear within ~10 seconds.

## Why this approach is better for your use case

- **No Google Cloud Console** — saves the OAuth dance entirely
- **One node instead of three** — simpler workflow, easier to debug
- **Easier to clone for new clients** — give each roofer their own Apps Script (5 min vs 20 min in Cloud Console)
- **Apps Script logs are easy to read** — `View → Executions` in the script editor shows every call

## When to switch back to native n8n nodes

If you ever need:
- **Real-time Sheet read operations** (e.g., look up if a phone number already exists)
- **More than ~20,000 webhook calls per day** (Apps Script's daily quota)
- **Two-way sync** between Sheets and another system

Then the native n8n Google Sheets node with proper OAuth is worth setting up. For Techo Buddy at this stage, Apps Script is plenty.
