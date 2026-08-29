// Supabase Edge Function: submit-agent-application
//
// Emails a "Register as an Agent" form submission to the Ona team via
// Resend instead of writing straight to travel_agents — applications are
// reviewed before a listing is created and shown on the public agent page.
// Deploy with:
//   supabase functions deploy submit-agent-application
//
// Required secrets:
//   RESEND_API_KEY          - Resend API key with sending access
//   AGENT_APPLICATION_EMAIL - inbox to notify (defaults to the Ona team's).
//                             Resend's shared onboarding@resend.dev sender
//                             can only deliver to the Resend account's own
//                             verified address until a sending domain is
//                             verified at resend.com/domains — after that,
//                             AGENT_APPLICATION_EMAIL can be any address and
//                             `from` below can move to that domain.
//
// Request body:
//   {
//     "businessName": string,
//     "bio": string | null,
//     "specialties": string[],
//     "languages": string[],
//     "yearsExperience": number | null,
//     "imageUrl": string | null,
//     "applicantEmail": string,
//     "applicantId": string
//   }
// Response body:
//   { "ok": true }

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const NOTIFY_EMAIL =
  Deno.env.get("AGENT_APPLICATION_EMAIL") ?? "onifadeifeoluwa1@gmail.com";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!RESEND_API_KEY) {
    console.error("submit-agent-application: RESEND_API_KEY is not set.");
    return jsonResponse(
      { error: "Agent applications are not configured yet." },
      500,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid request body." }, 400);
  }

  const businessName =
    typeof body.businessName === "string" ? body.businessName.trim() : "";
  if (!businessName) {
    return jsonResponse({ error: "businessName is required." }, 400);
  }

  const bio = typeof body.bio === "string" ? body.bio.trim() : "";
  const specialties = Array.isArray(body.specialties)
    ? body.specialties.map(String)
    : [];
  const languages = Array.isArray(body.languages)
    ? body.languages.map(String)
    : [];
  const yearsExperience =
    typeof body.yearsExperience === "number" ? body.yearsExperience : null;
  const imageUrl = typeof body.imageUrl === "string" ? body.imageUrl : null;
  const applicantEmail =
    typeof body.applicantEmail === "string" ? body.applicantEmail : null;
  const applicantId =
    typeof body.applicantId === "string" ? body.applicantId : "unknown";

  const rows: [string, string][] = [
    ["Business name", businessName],
    ["Bio", bio || "—"],
    ["Specialties", specialties.join(", ") || "—"],
    ["Languages", languages.join(", ") || "—"],
    ["Years of experience", yearsExperience?.toString() ?? "—"],
    ["Applicant email", applicantEmail ?? "unknown"],
    ["Applicant user id", applicantId],
  ];

  const html = `
    <h2>New Ọ̀nà agent application</h2>
    <table cellpadding="6" style="border-collapse:collapse">
      ${rows
        .map(
          ([label, value]) => `
        <tr>
          <td style="font-weight:600;vertical-align:top">${escapeHtml(label)}</td>
          <td>${escapeHtml(value)}</td>
        </tr>`,
        )
        .join("")}
    </table>
    ${imageUrl ? `<p><img src="${escapeHtml(imageUrl)}" alt="Applicant photo" width="120" /></p>` : ""}
  `;

  const text =
    rows.map(([label, value]) => `${label}: ${value}`).join("\n") +
    (imageUrl ? `\nPhoto: ${imageUrl}` : "");

  const emailResponse = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      Authorization: `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: "Ọ̀nà Agent Applications <onboarding@resend.dev>",
      to: [NOTIFY_EMAIL],
      reply_to: applicantEmail ?? undefined,
      subject: `New agent application: ${businessName}`,
      html,
      text,
    }),
  });

  if (!emailResponse.ok) {
    const errorText = await emailResponse.text();
    console.error("submit-agent-application: Resend error:", errorText);
    return jsonResponse({ error: "Could not send your application." }, 502);
  }

  return jsonResponse({ ok: true });
});
