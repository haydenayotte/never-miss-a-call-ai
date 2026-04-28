# Technical Integration Blueprint: Vapi + n8n + Google Sheets

This document outlines the technical architecture for connecting the bilingual AI voice receptionist to a lean lead management system using n8n and Google Sheets.

## 1. Vapi Assistant Configuration

### Tools Definition
The AI agents (English and Spanish) use specialized tools to capture structured data during the conversation.

#### Tool: `book_appointment`
- **Purpose**: Captures the requested date and time for a roof inspection.
- **Parameters**:
    - `datetime`: ISO 8601 string or natural language date/time.
    - `address`: The property address.

#### Tool: `transfer_to_spanish` (English Agent only)
- **Purpose**: Seamlessly transfers the caller to the Spanish-language assistant.
- **Action**: Vapi "Transfer" action to the Spanish Assistant ID.

---

## 2. Webhook Architecture (Vapi -> n8n)

At the conclusion of every call, Vapi sends a `call.ended` payload to the configured webhook URL.

### Data Payload Structure
Vapi transmits the following data points to the n8n trigger:
- `customer_number`: The caller's phone number.
* `transcript`: The full conversation text.
* `summary`: An AI-generated summary of the call.
* `variables`: Extracted data including `address`, `roof_size`, `material`, and `quote_range`.
* `recording_url`: A link to the audio recording.

---

## 3. n8n Workflow Logic

The n8n workflow serves as the "brain" that routes data from the voice agent to the database.

### Step 1: Webhook Trigger
Receives the POST request from Vapi.

### Step 2: Data Transformation
A 'Set' or 'Code' node parses the nested JSON from Vapi into a flat structure suitable for a spreadsheet.

### Step 3: Google Sheets Integration
- **Action**: Append Row.
- **Target**: The client-specific Lead Master Sheet.
- **Sheet Structure**:
    - **A: Timestamp** (Call End Time)
    - **B: Lead Name** (Captured from Caller ID or Conversation)
    - **C: Phone Number**
    - **D: Property Address**
    - **E: Roof Size** (Est. SqFt)
    - **F: Material** (Standard/Premium)
    - **G: Quote Range**
    - **H: Urgency** (Active Leak?)
    - **I: Appointment** (Requested Time)
    - **J: Summary**
    - **K: Recording URL**
- **Mapping**: Matches Vapi variables to the above columns.

### Step 4: Multi-Channel Notifications
- **Primary**: Twilio SMS to the roofing company owner with a summary and booking time.
- **Secondary**: Email or Slack alert with the full transcript link.

---

## 4. Error Handling & Continuity

- **Incomplete Calls**: If a caller hangs up before providing an address or booking an appointment, the webhook still fires. The lead is recorded in Google Sheets with a `Status: Incomplete` flag for manual follow-up.
- **Bilingual Continuity**: The system tracks the `call_id` across transfers to ensure that if a caller starts in English and switches to Spanish, they are recorded as a single lead entry.
