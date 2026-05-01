#!/usr/bin/env python3
"""
Creates the Privacy Policy and Terms of Service as new pages in Notion under
the Techo Buddy parent page. Reads the markdown source files, converts them
to Notion blocks, and creates the pages with proper formatting.

LIMITATION: Notion's public API cannot toggle "Publish to web". After this
script finishes, open each page in Notion → top-right Share → toggle Publish
ON to get the public notion.site URLs you need for Twilio.

PREREQUISITES (in .env):
  NOTION_TOKEN=secret_...
  NOTION_PARENT_PAGE_ID=...   (the "Techo Buddy" page, shared with the integration)

USAGE:
  cd "/Users/haydenayotte/Claude Businesses/never-miss-a-call-ai"
  python3 scripts/notion-publish-legal.py
"""

import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
ENV_FILE = PROJECT_ROOT / ".env"


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


env = load_env()
NOTION_TOKEN = env.get("NOTION_TOKEN", "")
PARENT_ID_RAW = env.get("NOTION_PARENT_PAGE_ID", "")
PARENT_ID = PARENT_ID_RAW.replace("-", "")

if not NOTION_TOKEN:
    sys.exit("ERROR: NOTION_TOKEN not set in .env")
if not PARENT_ID:
    sys.exit("ERROR: NOTION_PARENT_PAGE_ID not set in .env")


# ---------- Markdown → Notion blocks ----------

def parse_inline(text):
    """Convert inline markdown (bold, italic, code) to Notion rich_text."""
    rich = []
    pos = 0

    # Match **bold** OR *italic* OR `code` (not nested)
    pattern = re.compile(r"\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`")
    for m in pattern.finditer(text):
        if m.start() > pos:
            rich.append({"type": "text", "text": {"content": text[pos:m.start()]}})
        if m.group(1) is not None:
            rich.append({
                "type": "text",
                "text": {"content": m.group(1)},
                "annotations": {"bold": True},
            })
        elif m.group(2) is not None:
            rich.append({
                "type": "text",
                "text": {"content": m.group(2)},
                "annotations": {"italic": True},
            })
        elif m.group(3) is not None:
            rich.append({
                "type": "text",
                "text": {"content": m.group(3)},
                "annotations": {"code": True},
            })
        pos = m.end()
    if pos < len(text):
        rich.append({"type": "text", "text": {"content": text[pos:]}})
    if not rich:
        rich = [{"type": "text", "text": {"content": text}}]
    return rich


def block_heading(text, level):
    level = min(max(level, 1), 3)
    return {
        "object": "block",
        "type": f"heading_{level}",
        f"heading_{level}": {"rich_text": parse_inline(text)},
    }


def block_paragraph(text):
    return {
        "object": "block",
        "type": "paragraph",
        "paragraph": {"rich_text": parse_inline(text)},
    }


def block_bullet(text):
    return {
        "object": "block",
        "type": "bulleted_list_item",
        "bulleted_list_item": {"rich_text": parse_inline(text)},
    }


def block_numbered(text):
    return {
        "object": "block",
        "type": "numbered_list_item",
        "numbered_list_item": {"rich_text": parse_inline(text)},
    }


def md_to_blocks(text):
    blocks = []
    paragraph_buffer = []

    def flush_paragraph():
        if paragraph_buffer:
            joined = " ".join(paragraph_buffer).strip()
            if joined:
                blocks.append(block_paragraph(joined))
            paragraph_buffer.clear()

    lines = text.split("\n")
    in_table = False
    for raw in lines:
        line = raw.rstrip()

        # Skip table rows entirely (Notion API doesn't accept them via children;
        # they require a separate table block API which we skip for v1)
        if line.lstrip().startswith("|"):
            in_table = True
            continue
        if in_table and not line.strip():
            in_table = False
            continue

        if not line.strip():
            flush_paragraph()
            continue

        # Headings
        m = re.match(r"^(#{1,3})\s+(.+)$", line)
        if m:
            flush_paragraph()
            level = len(m.group(1))
            blocks.append(block_heading(m.group(2).strip(), level))
            continue

        # Bulleted list
        m = re.match(r"^\s*[-*+]\s+(.+)$", line)
        if m:
            flush_paragraph()
            blocks.append(block_bullet(m.group(1).strip()))
            continue

        # Numbered list
        m = re.match(r"^\s*\d+\.\s+(.+)$", line)
        if m:
            flush_paragraph()
            blocks.append(block_numbered(m.group(1).strip()))
            continue

        # Plain paragraph (accumulate consecutive lines)
        paragraph_buffer.append(line.strip())

    flush_paragraph()
    return blocks


# ---------- Notion API ----------

def notion_request(method, endpoint, body=None):
    url = f"https://api.notion.com/v1/{endpoint}"
    headers = {
        "Authorization": f"Bearer {NOTION_TOKEN}",
        "Notion-Version": "2022-06-28",
        "Content-Type": "application/json",
    }
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        sys.exit(f"Notion API error {e.code}: {body}")
    except urllib.error.URLError as e:
        sys.exit(f"Network error: {e}")


def create_page(title, icon_emoji, blocks):
    # Notion API limit: 100 children per create request
    first_chunk = blocks[:100]
    body = {
        "parent": {"type": "page_id", "page_id": PARENT_ID},
        "icon": {"type": "emoji", "emoji": icon_emoji},
        "properties": {
            "title": {
                "title": [{"type": "text", "text": {"content": title}}]
            }
        },
        "children": first_chunk,
    }
    page = notion_request("POST", "pages", body)
    page_id = page["id"]

    # Append remaining blocks (if any) in 100-block chunks
    remaining = blocks[100:]
    while remaining:
        chunk = remaining[:100]
        notion_request(
            "PATCH",
            f"blocks/{page_id}/children",
            {"children": chunk},
        )
        remaining = remaining[100:]

    return page


# ---------- Main ----------

def main():
    docs = [
        ("Privacy Policy", PROJECT_ROOT / "legal" / "privacy-policy.md", "🔒"),
        ("Terms of Service", PROJECT_ROOT / "legal" / "terms-of-service.md", "📜"),
    ]

    results = []
    for title, path, icon in docs:
        if not path.exists():
            print(f"  SKIP: {path} not found")
            continue
        text = path.read_text(encoding="utf-8")
        blocks = md_to_blocks(text)
        print(f"==> Creating '{title}' ({len(blocks)} blocks)...")
        page = create_page(title, icon, blocks)
        url = page.get("url", "")
        page_id = page.get("id", "")
        results.append((title, url, page_id))
        print(f"    OK. Page URL: {url}")

    print("\n" + "=" * 60)
    print("LEGAL PAGES CREATED")
    print("=" * 60)
    for title, url, _ in results:
        print(f"  {title}")
        print(f"    {url}")

    print("""
FINAL MANUAL STEP (Notion API can't toggle this — 10 sec per page):

  1. Open each page in Notion (links above).
  2. Top-right: click Share.
  3. Toggle Publish to ON.
  4. Click "Copy web link" — that's the URL Twilio wants
     (will look like: yourworkspace.notion.site/...).

Paste those public URLs into Twilio's A2P 10DLC registration form for
"Privacy Policy URL" and "Terms of Service URL".
""")


if __name__ == "__main__":
    main()
