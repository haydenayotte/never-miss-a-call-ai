# Publishing Your Privacy Policy and Terms — 5 Minutes

You need public URLs for both documents to satisfy Twilio's A2P 10DLC registration. The fastest path is publishing them as Notion public pages — Twilio accepts this and you can update them anytime.

## Step 1 — Create the Pages in Notion (3 min)

1. In your Notion workspace (where you already created the "Techo Buddy" parent page), click **+ Add a page**.
2. Title it: **Privacy Policy**.
3. Open `legal/privacy-policy.md` from this project, copy the entire contents, and paste into the new Notion page. Notion will automatically render the markdown.
4. Repeat for Terms of Service:
   - Click **+ Add a page** → title **Terms of Service** → paste contents of `legal/terms-of-service.md`.

## Step 2 — Make Each Page Public (1 min each)

For each page:

1. Click **Share** (top-right of the page).
2. Toggle **Publish** to ON.
3. Optionally enable: **Allow search engines to index this page** (helps with SEO; not required for Twilio).
4. Click **Copy web link** — this is your public URL.

You'll get URLs that look like:
```
https://yourworkspace.notion.site/Privacy-Policy-abc123def456...
https://yourworkspace.notion.site/Terms-of-Service-xyz789...
```

## Step 3 — Use Them in Twilio Registration

Paste the Privacy Policy URL when Twilio asks for it during A2P registration. Same for Terms.

## Step 4 — Fill in the Placeholders

Both documents have a few placeholders you need to fill in **before** submitting to Twilio (the carriers will check they look real):

| Placeholder | Where it appears | Replace with |
|---|---|---|
| `[Your business phone]` | Privacy Policy §9, Terms §12 | Your Twilio number, formatted like "(555) 123-4567" |
| `[Your State]` | Terms §10 | The state where you live or the LLC is registered |
| `[Your County]` | Terms §10 | Your county |

Edit directly in Notion (the changes are live instantly because the Notion page mirrors the source).

## What if you have a real website later?

When you eventually launch a real `techobuddy.com`, mirror these same documents there at:
- `techobuddy.com/privacy`
- `techobuddy.com/terms`

Then update your Twilio registration to point to the new URLs. Twilio doesn't recheck approved campaigns frequently, so you can update gradually.

## A note on legal review

These templates cover the common A2P / TCPA compliance language carriers expect to see, and they're good enough for Twilio approval and a demo-stage business. **They are not a substitute for actual legal advice.** Once you have paying clients (especially clients in regulated states like California, Colorado, or Texas), have a small-business attorney spend an hour reviewing them. Expect to pay $200-500 for a one-off review. Resources:

- LegalZoom: ~$300 for both documents reviewed and customized
- Local bar association referral lists
- Small-business clinics at local law schools (often free)

## Optional upgrade — generated policies via free tools

If you want a more polished version generated specifically for your business details, these free tools work well:

- https://www.privacypolicies.com (free tier; ad-supported)
- https://www.termly.io (free with branding; paid removes branding)
- https://www.getterms.io (paid, ~$25 one-time)

You can paste their output back into the same Notion pages.
