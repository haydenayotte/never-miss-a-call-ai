# Never Miss A Call AI

## Business Overview
**Never Miss A Call** is an AI voice receptionist business that sells done-for-you bilingual phone agents to roofing companies operating in heavily Spanish-speaking markets such as Los Angeles, Houston, Miami, San Antonio, Phoenix, and Dallas.

Our core product is a fully configured bilingual AI voice agent built on GoHighLevel that:
- Answers every inbound call in both English and Spanish.
- Delivers an instant tentative roof replacement quote based on the caller's address.
- Qualifies the lead (repair vs. replacement, insurance claims, urgency).
- Books an on-site inspection appointment before ending the call.
- Works 24/7, never misses a call, and never takes a break.

### How It Works
The system uses two coordinated AI agents. The first agent answers in English and immediately transfers the call to a dedicated Spanish-language agent if the caller prefers Spanish. The Spanish agent has a native voice and a prompt written entirely in Spanish.

Both agents use custom prompt logic for automatic quote calculation based on roof size, material type, and industry standards.

## Repository Structure

- `agent/`: Contains the core logic and prompts for the AI voice agents.
  - `agent_logic.md`: Prompt engineering and logic definitions.
- `technical/`: Technical documentation and automation blueprints.
  - `technical_blueprint.md`: System architecture and GoHighLevel configuration.
  - `n8n_blueprint.md`: Integration workflows for data syncing and notifications.
- `sales/`: Sales strategy, scripts, and lead lists.
  - `sales_strategy.md`: Overall go-to-market strategy.
  - `lead_delivery_pitch.md`: Script for delivering leads to clients.
  - `target_leads.csv`: Initial list of high-value prospects.
  - `assets/`: Detailed sales tools including outreach templates, pitch decks, and ROI proofs.
- `guides/`: Standard Operating Procedures and delivery guides.
  - `delivery_guide.md`: Step-by-step instructions for onboarding new clients.

## Getting Started
To deploy this system for a new client:
1. Review the `technical/technical_blueprint.md` for GoHighLevel setup.
2. Implement the workflows in `technical/n8n_blueprint.md`.
3. Configure the Vapi/GoHighLevel agents using the logic in `agent/agent_logic.md`.
4. Follow the `guides/delivery_guide.md` for client onboarding and handoff.
