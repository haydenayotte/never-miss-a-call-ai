# Notion Database Setup — Techo Buddy Leads

A Notion database that mirrors the Google Sheet but adds kanban-style status tracking. Used as the demo CRM view when pitching roofing contractors.

## Step 1: Create the Database

1. In Notion, create a new page titled **"Techo Buddy Leads"**.
2. Type `/database - full page` and select **Database — Full page**.
3. Rename the database **"Leads"**.

## Step 2: Configure Properties

Replace the default properties with the following. The **exact property names matter** — n8n maps fields by these names.

| Property Name | Type | Notes / Options |
|---|---|---|
| Lead Name | Title | (default) |
| Status | Status (or Select) | Options: `New`, `Contacted`, `Booked`, `Inspected`, `Won`, `Lost` |
| Phone | Phone |  |
| Language | Select | Options: `English`, `Spanish` |
| Service Type | Select | Options: `Repair`, `Replacement`, `Inspection Only`, `Unknown` |
| Address | Text |  |
| Roof Size (sqft) | Number | Format: Number |
| Material | Select | Options: `Standard`, `Premium`, `Unknown` |
| Quote Low | Number | Format: Dollar ($) |
| Quote High | Number | Format: Dollar ($) |
| Urgency | Select | Options: `Active Leak`, `This Week`, `This Month`, `Planning`, `Unknown` |
| Insurance Claim | Checkbox |  |
| Appointment Booked | Checkbox |  |
| Appointment | Date | Include time |
| Lead Quality | Select | Options: `Hot`, `Warm`, `Cold` |
| Follow-up Notes | Text |  |
| Summary | Text |  |
| Recording | URL |  |
| Call ID | Text | Hidden in default view |
| Created | Created time | (auto) |

## Step 3: Set Default View to Board

1. Click **+ Add a view** → **Board**.
2. **Group by**: `Status`.
3. **Columns**: drag `New` first, then `Contacted`, `Booked`, `Inspected`, `Won`, `Lost`.

This gives you a Kanban view that's great for demos.

## Step 4: Create a Notion Internal Integration

n8n needs API access to write to this database.

1. Go to https://www.notion.so/my-integrations
2. Click **+ New integration**.
3. Name: `Techo Buddy n8n`. Workspace: your workspace.
4. Capabilities: `Read content`, `Update content`, `Insert content`. (Leave User Capabilities at "No user information".)
5. Click **Submit**, then copy the **Internal Integration Secret**. Save it as `NOTION_TOKEN` in the project `.env`:

   ```
   NOTION_TOKEN=secret_abc123...
   ```

## Step 5: Share the Database with the Integration

1. Open the **Leads** database in Notion.
2. Top right, click the `•••` menu → **Connections** → **Add connections** → select `Techo Buddy n8n`.
3. Confirm.

## Step 6: Get the Database ID

The database ID is the 32-char string in the URL when viewing the database:

```
https://www.notion.so/myworkspace/abc123def456...?v=...
                                  ^^^^^^^^^^^^^^^^
                                  this part
```

Save it to `.env`:

```
NOTION_DATABASE_ID=abc123def456...
```

## Done

Your Notion database is ready. The n8n workflow will write a new page to this database every time a call ends.
