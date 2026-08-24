// Supabase Edge Function: ai-assistant
//
// Proxies a chat conversation to the Anthropic Messages API using a
// server-side secret (ANTHROPIC_API_KEY), so the key never ships inside the
// Flutter app. Deploy with:
//   supabase functions deploy ai-assistant
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//
// Request body:  { "messages": [{ "role": "user" | "assistant", "content": string }] }
// Response body: { "reply": string }

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-sonnet-5";

const SYSTEM_PROMPT =
  "You are the Ona travel assistant. Help travelers discover destinations, " +
  "plan itineraries, find restaurants and activities, and answer practical " +
  "travel questions (visas, packing, safety, budgeting). Keep replies " +
  "warm, concise, and focused on travel.";

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
    const { messages } = await req.json();
    if (!Array.isArray(messages) || messages.length === 0) {
      return jsonResponse({ error: "messages is required" }, 400);
    }

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: messages.map((message: { role: string; content: string }) => ({
          role: message.role === "assistant" ? "assistant" : "user",
          content: message.content,
        })),
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return jsonResponse({ error: `Anthropic API error: ${errorText}` }, 502);
    }

    const data = await response.json();
    const reply = data.content?.[0]?.text ?? "";

    return jsonResponse({ reply });
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});
