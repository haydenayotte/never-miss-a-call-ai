# Service Delivery & Demo Guide: Never Miss A Call

This guide outlines the internal delivery process and the demonstration script used to sell the bilingual AI receptionist to roofing company owners.

---

## I. Service Delivery & Onboarding Guide (The 24-Hour Checklist)

### 1. Rapid Deployment Workflow (T-Minus 24 Hours)
Follow these steps to get a new roofing client live within one business day:

**Phase 1: Database & Voice Setup (Hours 0-4)**
1.  **Google Sheets Setup**:
    - Duplicate the "Never Miss A Call" Lead Master Template.
    - Share the sheet with the client and internal team.
2.  **Number Acquisition & Mapping**:
    - Provision a new local number directly in Vapi or port the client's number.
    - Link the number to the primary English Assistant.

**Phase 2: AI Customization (Hours 4-8)**
3.  **Voice AI (VAPI) Deployment**:
    - Duplicate the master English and Spanish Assistants.
    - **Prompt Customization**: Replace `[Company Name]` with the client's business name.
    - **Pricing Calibration**: Update the material multipliers in the prompt if the client requires custom pricing (e.g., $8/sqft instead of $7).
4.  **Bilingual Handoff Test**:
    - Run a test call to the English agent, speak Spanish, and verify the transfer works perfectly.

**Phase 3: Automation & Notification (Hours 8-16)**
5.  **n8n Workflow Sync**:
    - Deploy the standard n8n blueprint for the client.
    - Connect the Vapi post-call webhook to the n8n trigger.
    - Test the webhook by completing a dummy call and checking if the row is appended to the Google Sheet.
6.  **Notification Testing**:
    - Ensure the client's mobile number is correctly configured in n8n/Twilio to receive instant lead alerts.

**Phase 4: QA & Handover (Hours 16-24)**
7.  **End-to-End QA**:
    - Perform 3 test calls: One for English repair, one for English replacement with booking, and one Spanish transfer with booking.
8.  **Client Handover**:
    - Send the client their login credentials and the "Lead Alert" notification test.

### 2. Client Onboarding Checklist
Information required from the roofing company owner before go-live:

- [ ] **Legal Business Name**: How the AI should identify the company.
- [ ] **Service Area**: Specific counties/cities served (to help the AI confirm serviceability).
- [ ] **Pricing Tiers**: Confirm if our standard ($7/$12 per sq ft) works or if adjustments are needed.
- [ ] **Emergency Policy**: Does the client handle emergency tarping/repairs immediately?
- [ ] **Calendar Link**: Access to a booking calendar.
- [ ] **Notification Contacts**: Mobile numbers/emails for the staff who should receive lead alerts.

---

## II. Live Demo Script: "The Leaky Roof Scenario"

This script is designed for a live demonstration with a prospect. One team member plays the AI, or we use the live staging number.

**Character**: "Late-Night Larry" (Homeowner)
**Context**: 10:30 PM on a rainy Tuesday. Larry is stressed.

### The Scripted Interaction

1.  **AI (English)**: "Thank you for calling [Company Name], this is your AI assistant. How can I help you with your roof today?"
2.  **Larry**: "Yeah, hi. It's late but I just saw a leak in my guest bedroom ceiling. We had that storm an hour ago. Do you guys do emergency repairs?"
3.  **AI**: "I'm sorry to hear that, Larry. We definitely handle active leaks. To help you best, what's the address of the property?"
4.  **Larry**: "123 Maple Street, Dallas."
5.  **AI**: "Got it. While our crew can look at the leak, are you considering a full replacement if the damage is significant, or just a patch for now?"
6.  **Larry**: "The roof is 20 years old, so probably a replacement if the price is right."
7.  **AI**: "Understood. Do you know the approximate square footage of your roof? Or just the house size?"
8.  **Larry**: "House is about 2,200 square feet."
9.  **AI**: "Based on a home that size, a standard replacement would typically range between $20,000 and $25,000. To give you an exact number and address that leak, I'd like to get a pro out there. Does tomorrow at 9:00 AM work, or would 1:00 PM be better?"
10. **Larry**: "Let's do 9:00 AM. I need this fixed."
11. **AI**: "Perfect. We have you down for 9:00 AM tomorrow. You'll get a confirmation text in a moment. Rest easy, Larry!"

### Demo Key Points to Highlight to the Prospect:
- **Instant Response**: No voicemail, no waiting.
- **Qualification**: Captured address, urgency (leak), and intent (replacement).
- **Price Anchoring**: Delivered a realistic range immediately, keeping the lead on the hook.
- **Conversion**: The call ended with a firm appointment on the calendar.
