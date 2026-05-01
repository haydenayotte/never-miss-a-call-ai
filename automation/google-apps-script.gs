/**
 * Techo Buddy — Google Apps Script Webhook
 *
 * Receives lead data from n8n and:
 *   1. Appends a row to your Google Sheet
 *   2. Creates a Google Calendar event (if the caller booked an inspection)
 *
 * Runs as YOU on Google's servers — no OAuth client setup needed.
 * Deploy as a Web App with "Anyone" access. The URL becomes your webhook
 * destination in n8n's HTTP Request node.
 *
 * SETUP:
 *   1. Replace SHEET_ID and CALENDAR_ID below.
 *   2. Click "Deploy" → "New deployment" → Type: Web app
 *   3. Execute as: Me; Who has access: Anyone
 *   4. Copy the deployment URL → paste into n8n HTTP Request node.
 */

// ═══ CONFIGURE THESE ═══════════════════════════════════════
const SHEET_ID    = 'YOUR_GOOGLE_SHEET_ID';      // from sheet URL
const SHEET_NAME  = 'Leads';                     // tab name (must match)
const CALENDAR_ID = 'primary';                   // 'primary' = your main calendar
                                                 // or paste the Calendar ID from
                                                 // Calendar Settings → Integrate
// ═══════════════════════════════════════════════════════════


function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);

    // 1. Append to Google Sheet
    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    sheet.appendRow([
      data.timestamp || new Date(),
      data.lead_name || 'Unknown',
      data.phone || '',
      data.language || '',
      data.service_type || '',
      data.address || '',
      Number(data.roof_size_sqft) || 0,
      data.material_preference || '',
      Number(data.quote_low) || 0,
      Number(data.quote_high) || 0,
      data.urgency || '',
      Boolean(data.insurance_claim),
      Boolean(data.appointment_booked),
      data.appointment_datetime || '',
      data.lead_quality || '',
      data.follow_up_notes || '',
      data.summary || '',
      data.recording_url || '',
      data.transcript || '',
      data.call_id || ''
    ]);

    // 2. Create Calendar event if appointment was booked
    let calendarEventId = null;
    if (data.appointment_booked && data.appointment_datetime) {
      const calendar = (CALENDAR_ID === 'primary')
        ? CalendarApp.getDefaultCalendar()
        : CalendarApp.getCalendarById(CALENDAR_ID);

      const start = new Date(data.appointment_datetime);
      const end = new Date(start.getTime() + 60 * 60 * 1000); // 1 hour duration

      const description = [
        'Lead from Techo Buddy AI receptionist.',
        '',
        `Caller: ${data.lead_name || 'Unknown'}`,
        `Phone: ${data.phone || 'N/A'}`,
        `Service: ${data.service_type || 'unknown'}`,
        `Quote Range: $${data.quote_low || 0} - $${data.quote_high || 0}`,
        `Material: ${data.material_preference || 'unknown'}`,
        `Urgency: ${data.urgency || 'unknown'}`,
        `Language: ${data.language || 'en'}`,
        '',
        `Notes: ${data.follow_up_notes || ''}`,
        '',
        `Summary: ${data.summary || ''}`,
        '',
        `Recording: ${data.recording_url || ''}`
      ].join('\n');

      const event = calendar.createEvent(
        `Roof Inspection — ${data.lead_name || 'Unknown'}`,
        start,
        end,
        {
          location: data.address || '',
          description: description
        }
      );
      calendarEventId = event.getId();
    }

    return ContentService
      .createTextOutput(JSON.stringify({
        ok: true,
        sheet_row_added: true,
        calendar_event_id: calendarEventId
      }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({
        ok: false,
        error: err.toString(),
        stack: err.stack
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}


// Test in the editor — runs the function with sample data so you can verify
// the script works without sending a real call.
function testWithSampleData() {
  const fakeRequest = {
    postData: {
      contents: JSON.stringify({
        timestamp: new Date().toISOString(),
        lead_name: 'Test Hayden',
        phone: '+19785181591',
        language: 'english',
        service_type: 'replacement',
        address: '123 Test St, Houston TX',
        roof_size_sqft: 3000,
        material_preference: 'standard',
        quote_low: 18900,
        quote_high: 23100,
        urgency: 'active_leak',
        insurance_claim: false,
        appointment_booked: true,
        appointment_datetime: new Date(Date.now() + 24*60*60*1000).toISOString(),
        lead_quality: 'hot',
        follow_up_notes: 'Active leak — high priority',
        summary: 'Test call from Apps Script editor',
        recording_url: 'https://example.com/test.mp3',
        call_id: 'test-' + Date.now()
      })
    }
  };
  const response = doPost(fakeRequest);
  Logger.log(response.getContent());
}
