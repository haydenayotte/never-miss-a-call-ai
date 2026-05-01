# IVR Workflow Setup (Press 1 / Press 2)

This guide builds the bilingual IVR front door in the Vapi dashboard. Time required: **~5 minutes**.

The architecture you're building:

```
Phone Number → Workflow (Bilingual greeting + DTMF capture) → English OR Spanish Assistant
```

You're doing this in the Vapi UI rather than via API because the visual workflow builder is faster and less error-prone for a 4-node flow.

---

## Prerequisites

- The setup script (`scripts/vapi-setup.sh`) has been run successfully.
- You have your assistant IDs saved (also in `.env` at the project root):
  - `VAPI_ENGLISH_ASSISTANT_ID`
  - `VAPI_SPANISH_ASSISTANT_ID`

---

## Step 1: Create the Workflow

1. Go to **https://dashboard.vapi.ai/workflows**.
2. Click **Create Workflow**.
3. Name it: `Techo Buddy - Language Router`.
4. Click **Create**.

You'll land in the visual builder with a single "Start" node.

---

## Step 2: Add the Bilingual Greeting

1. From the node palette, drag in a **Say** node (or "Conversation Start" / "Greeting" — name varies).
2. Connect it from the Start node.
3. Set the message:

   > Thank you for calling Techo Buddy. For English, press 1. Para español, oprima el dos.

4. Voice: pick a neutral ElevenLabs voice (e.g. **Sarah** or **Adam**). The same voice will read both languages — it's intentional and sounds professional.

---

## Step 3: Add the DTMF Capture Node

1. Drag in a **Gather DTMF** node (sometimes labeled "Wait for Keypress" or "DTMF Input").
2. Connect it after the greeting.
3. Configure:
   - **Number of digits**: `1`
   - **Timeout**: `5 seconds`
   - **No-input behavior**: re-prompt once, then default to English
   - **Variable name**: `language_choice` (this stores the keypress)

---

## Step 4: Add the Routing Branch

1. Drag in a **Conditional / Logic** node.
2. Add two branches:

   **Branch A — English**
   - Condition: `language_choice == 1`
   - Action: drag in an **Assistant** node
   - Select assistant: `Techo Buddy - English Receptionist`

   **Branch B — Spanish**
   - Condition: `language_choice == 2`
   - Action: drag in an **Assistant** node
   - Select assistant: `Techo Buddy - Spanish Receptionist`

   **Default branch (no match / timeout)**
   - Route to the English Assistant. Most accidental keypresses or non-presses are English speakers.

---

## Step 5: Save and Publish

1. Click **Save** (top right).
2. Click **Publish** (this makes it live for incoming calls).

---

## Step 6: Point Your Phone Number at the Workflow

1. Go to **Phone Numbers** in the Vapi dashboard.
2. Click your number (or buy one if you haven't yet).
3. Under **Inbound Settings**, change the destination:
   - **From**: any assistant currently selected (or "None")
   - **To**: `Techo Buddy - Language Router` (under "Workflow")
4. Click **Save**.

---

## Step 7: Test the Flow

Call the number from your cell phone. Run these four tests:

| Test | What you do | Expected result |
|------|-------------|-----------------|
| 1 | Press `1` after greeting | Lands on English Agent: "Thank you for calling Techo Buddy..." |
| 2 | Press `2` after greeting | Lands on Spanish Agent: "Gracias por llamar a Techo Buddy..." |
| 3 | Don't press anything | Re-prompts once, then routes to English by default |
| 4 | Press `1`, then ask for a quote on a 2,000 sqft home, asphalt | Quote should be ~$18,900 – $23,100 |

If any test fails, take a screenshot of the workflow and the call log (in Vapi → Calls), and share with Claude in chat for debugging.

---

## Common gotchas

- **Greeting plays in a robotic English voice.** Pick an ElevenLabs voice (not the default PlayHT) for the Say node.
- **Pressing 2 doesn't work.** Make sure the DTMF node is set to capture **exactly 1 digit** with no "finish key" required.
- **Spanish agent answers in English.** Verify the Spanish assistant has `transcriber.language: "es"` and the system prompt is in Spanish (it should be — the JSON we generated handles this).
- **Caller hears silence on transfer.** That's normal for ~1 second between the workflow and the assistant. Don't let it spook you.
