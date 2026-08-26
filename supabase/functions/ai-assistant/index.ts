// Supabase Edge Function: ai-assistant
//
// Proxies chat turns to the Gemini API (free tier) using a server-side
// secret (GEMINI_API_KEY), so the key never ships inside the Flutter app.
// Deploy with:
//   supabase functions deploy ai-assistant
//   supabase secrets set GEMINI_API_KEY=...
//
// Uses Gemini's Interactions API (https://generativelanguage.googleapis.com/
// v1beta/interactions), which tracks conversation state server-side — each
// request sends only the newest user message plus the previous interaction's
// id, instead of replaying the full history.
//
// Live web grounding uses Brave Search's free API tier (2,000 queries/month,
// no card required — https://api.search.brave.com). When the latest user
// message looks time-sensitive (prices, hours, weather, news, etc. — see
// SEARCH_TRIGGER_PATTERN), one Brave search runs and the top results are
// injected into the prompt as context. Set BRAVE_API_KEY to enable it;
// without it, or on a search failure, the assistant just answers from
// training data — search never breaks the chat.
//   supabase secrets set BRAVE_API_KEY=...
//
// Request body:  {
//   "message": string,
//   "previousInteractionId": string | null
// }
// Response body: { "reply": string, "interactionId": string }

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.7-flash";
const BRAVE_API_KEY = Deno.env.get("BRAVE_API_KEY");

const BASE_SYSTEM_PROMPT =
  "You are the Ona travel assistant. Help travelers discover destinations, " +
  "plan itineraries, find restaurants and activities, and answer practical " +
  "travel questions (visas, packing, safety, budgeting). Keep replies warm, " +
  "concise, and focused on travel. You're shown in a simple mobile chat " +
  "bubble, not a markdown renderer — only use plain text, '### ' headers, " +
  "'**bold**', and '* ' bullets if you need structure; avoid nested lists, " +
  "links, tables, or other markdown.";

interface BraveResult {
  title: string;
  url: string;
  description: string;
}

// Only search for messages that plausibly need live/current info — avoids
// burning free-tier quota (and tacking on an irrelevant "Sources" footer) on
// greetings, small talk, or questions answerable from stable knowledge.
const SEARCH_TRIGGER_PATTERN =
  /\b(price|prices|cost|costs|cheap|expensive|budget|exchange rate|currency|weather|forecast|temperature|rain|snow|climate|today|tonight|tomorrow|now|currently|current|latest|recent|update|updated|news|open|opening|closed|closing|hours|schedule|timing|event|events|festival|holiday|visa|entry requirement|passport requirement|covid|advisory|safety|strike|flight|flights|book|booking|availability|available)\b/i;

function needsSearch(message: string): boolean {
  return SEARCH_TRIGGER_PATTERN.test(message);
}

/**
 * One free-tier Brave Search call for the given query. Returns an empty
 * array (never throws) on missing key, network error, or non-2xx response,
 * so a search hiccup degrades to "answer without web context" instead of
 * failing the whole chat request.
 */
async function braveSearch(query: string, count = 5): Promise<BraveResult[]> {
  if (!BRAVE_API_KEY) return [];
  try {
    const url = new URL("https://api.search.brave.com/res/v1/web/search");
    url.searchParams.set("q", query);
    url.searchParams.set("count", String(count));

    const response = await fetch(url, {
      headers: {
        Accept: "application/json",
        "X-Subscription-Token": BRAVE_API_KEY,
      },
    });
    if (!response.ok) return [];

    const data = await response.json();
    const results = data?.web?.results;
    if (!Array.isArray(results)) return [];

    return results.slice(0, count).map((result: Record<string, unknown>) => ({
      title: String(result.title ?? ""),
      url: String(result.url ?? ""),
      description: String(result.description ?? ""),
    }));
  } catch {
    return [];
  }
}

function buildSystemInstruction(searchResults: BraveResult[]): string {
  if (searchResults.length === 0) return BASE_SYSTEM_PROMPT;

  const context = searchResults
    .map((r, i) => `${i + 1}. ${r.title} (${r.url})\n${r.description}`)
    .join("\n\n");

  return (
    `${BASE_SYSTEM_PROMPT}\n\n` +
    "Here are live web search results for the user's latest message. Use " +
    "them if relevant to give an up-to-date answer (prices, hours, weather, " +
    "events, news); ignore them if they don't apply. Don't mention that " +
    "you were given search results — just answer naturally.\n\n" +
    `${context}`
  );
}

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

  if (!GEMINI_API_KEY) {
    return jsonResponse(
      { error: "GEMINI_API_KEY is not configured on this project." },
      500,
    );
  }

  try {
    const { message, previousInteractionId } = await req.json();
    if (typeof message !== "string" || message.trim().length === 0) {
      return jsonResponse({ error: "message is required" }, 400);
    }

    const searchResults = needsSearch(message)
      ? await braveSearch(message)
      : [];

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/interactions",
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": GEMINI_API_KEY,
        },
        body: JSON.stringify({
          model: GEMINI_MODEL,
          system_instruction: buildSystemInstruction(searchResults),
          input: message,
          // A lightweight chat assistant doesn't need deep reasoning — keep
          // thinking cheap so free-tier quota goes toward actual replies.
          generation_config: { thinking_level: "low" },
          ...(previousInteractionId
            ? { previous_interaction_id: previousInteractionId }
            : {}),
        }),
      },
    );

    if (!response.ok) {
      const errorText = await response.text();
      return jsonResponse({ error: `Gemini API error: ${errorText}` }, 502);
    }

    const data = await response.json();
    // The raw REST response has no top-level "output_text" — that's only a
    // convenience property in Google's SDK wrappers. The real text lives in
    // steps[].content[].text on "model_output" steps.
    const steps = Array.isArray(data.steps) ? data.steps : [];
    let reply = steps
      .filter((step: { type: string }) => step.type === "model_output")
      .flatMap((step: { content?: { type: string; text?: string }[] }) =>
        step.content ?? []
      )
      .filter((block: { type: string }) => block.type === "text")
      .map((block: { text?: string }) => block.text ?? "")
      .join("")
      .trim();

    if (searchResults.length > 0) {
      const sources = searchResults
        .map((r) => `- ${r.title}: ${r.url}`)
        .join("\n");
      reply += `\n\nSources:\n${sources}`;
    }

    return jsonResponse({ reply, interactionId: data.id });
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});
