# Lean Stack Blueprint: Vapi + n8n + Google Sheets

This blueprint provides a cost-effective, high-speed alternative to GoHighLevel for managing roofing leads. It is ideal for smaller clients or for testing new markets rapidly.

## 1. Google Sheets Template Structure

Create a new Google Sheet with the following headers in the first row:

| Column | Header | Data Type |
| :--- | :--- | :--- |
| A | **Timestamp** | DateTime |
| B | **Lead Name** | Text |
| C | **Phone Number** | Phone |
| D | **Property Address** | Text |
| E | **Service Type** | Text (Repair/Replacement) |
| F | **Roof Size (Est. SqFt)** | Number |
| G | **Material Preference** | Text |
| H | **Quote Range Low** | Currency |
| I | **Quote Range High** | Currency |
| J | **Urgency** | Text |
| K | **Insurance Claim** | Text (Yes/No) |
| L | **Appointment Date/Time** | Text/DateTime |
| M | **Call Summary** | Text |
| N | **Recording Link** | URL |

---

## 2. n8n Workflow Architecture

The n8n workflow consists of four primary nodes.

### Node 1: Webhook (The Trigger)
- **Method**: POST
- **Path**: `vapi-webhook`
- **Authentication**: None (or Header Auth for security)
- **Responsibility**: Listens for the `call.ended` or `call.tool_call` event from Vapi.

### Node 2: Data Parser (JSON Transformation)
**Example Mapping (n8n Expressions):**
- `Lead Name`: `{{ $json.customer.name || "Unknown" }}`
- `Phone`: `{{ $json.customer.number }}`
- `Address`: `{{ $json.artifact.messages[0].arguments.address }}` (example depends on tool call)
- `Quote`: `{{ $json.artifact.messages[0].arguments.quote_low }}`

### Node 3: Google Sheets (Append Row)
- **Operation**: Append
- **Resource**: Row
- **Mapping**: Map the parsed fields from Node 2 to the columns defined in Section 1.

### Node 4: Notification (SMS/Email)
- **Channel 1 (Twilio)**: Send an SMS to the roofing company owner.
    - *Body*: "New AI Lead: {name} at {address}. Est Quote: {quote_low}-{quote_high}. Appointment: {appointment_time}."
- **Channel 2 (Email/Slack)**: Optional secondary notification with the full call summary.

---

## 3. Implementation Steps

1.  **Vapi Config**:
    - In the Vapi Dashboard, go to **Assistants** -> **Webhooks**.
    - Paste the n8n Webhook URL.
2.  **n8n Setup**:
    - Import the workflow (template logic provided above).
    - Authenticate Google Sheets and Twilio credentials.
3.  **Testing**:
    - Trigger a test call.
    - Verify the row appears in Google Sheets within 5 seconds of the call ending.
    - Confirm the SMS notification is received.

---

## 4. Why Use the Lean Stack?
- **Cost**: Eliminates the monthly $297+ GHL fee.
- **Speed**: Setup takes < 15 minutes.
- **Simplicity**: No complex CRM workflows; just a spreadsheet that anyone can use.
