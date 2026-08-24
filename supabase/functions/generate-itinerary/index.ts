// Supabase Edge Function: generate-itinerary
//
// Asks the Anthropic Messages API for a structured day-by-day itinerary,
// using the same server-side ANTHROPIC_API_KEY secret as ai-assistant.
// Deploy with:
//   supabase functions deploy generate-itinerary
//
// Request body:
//   { "destination": string, "days": number, "budget": "budget" | "moderate" | "luxury" }
// Response body:
//   { "title": string, "description": string, "days": [{ "day": number, "activities": string[] }] }

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-sonnet-5";

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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!ANTHROPIC_API_KEY) {
    return jsonResponse(
      { error: "ANTHROPIC_API_KEY is not configured on this project." },
      500,
    );
  }

  try {
    const { destination, days, budget } = await req.json();
    if (!destination || !days) {
      return jsonResponse({ error: "destination and days are required" }, 400);
    }

    const prompt =
      `Plan a ${days}-day ${budget ?? "moderate"}-budget trip to ${destination}. ` +
      "Respond with ONLY minified JSON (no prose, no markdown fences) matching " +
      'exactly this shape: {"title": string, "description": string, ' +
      '"days": [{"day": number, "activities": string[]}]}. ' +
      `Include exactly ${days} entries in "days", each with 3-5 concrete, ` +
      "specific activities (name real places where you can).";

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 2048,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return jsonResponse({ error: `Anthropic API error: ${errorText}` }, 502);
    }

    const data = await response.json();
    const rawText = data.content?.[0]?.text ?? "{}";
    const start = rawText.indexOf("{");
    const end = rawText.lastIndexOf("}");
    const jsonText = start >= 0 && end >= start ? rawText.slice(start, end + 1) : "{}";

    let itinerary;
    try {
      itinerary = JSON.parse(jsonText);
    } catch {
      itinerary = {
        title: `${days}-Day Trip to ${destination}`,
        description: rawText,
        days: [],
      };
    }

    return jsonResponse(itinerary);
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});
