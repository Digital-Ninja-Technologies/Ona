// Supabase Edge Function: ai-assistant
//
// Proxies a chat conversation to the Anthropic Messages API using a
// server-side secret (ANTHROPIC_API_KEY), so the key never ships inside the
// Flutter app. Deploy with:
//   supabase functions deploy ai-assistant
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//
// The web_search server tool is enabled so Ona can pull current info (prices,
// hours, events, conditions) from the live web instead of only its training
// data. Each search is billed at $10/1,000 searches plus standard token
// costs for the results — max_uses caps that per turn.
//
// Request body:  { "messages": [{ "role": "user" | "assistant", "content": string }] }
// Response body: { "reply": string }

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-sonnet-5";

const SYSTEM_PROMPT =
  "You are the Ona travel assistant. Help travelers discover destinations, " +
  "plan itineraries, find restaurants and activities, and answer practical " +
  "travel questions (visas, packing, safety, budgeting). You have live web " +
  "search — use it for anything time-sensitive (current prices, opening " +
  "hours, weather, events, news) rather than relying on memory. Keep " +
  "replies warm, concise, and focused on travel.";

interface AnthropicCitation {
  type: string;
  url?: string;
  title?: string;
  cited_text?: string;
}

interface AnthropicContentBlock {
  type: string;
  text?: string;
  citations?: AnthropicCitation[];
}

/**
 * Anthropic responses that use the web_search tool interleave text blocks
 * with server_tool_use / web_search_tool_result blocks, so the final answer
 * usually isn't content[0] — it's the last text block. Concatenate every
 * text block in order, and collect any cited sources so we can surface them.
 */
function extractReply(content: AnthropicContentBlock[]): string {
  const textParts: string[] = [];
  const sources = new Map<string, string>(); // url -> title

  for (const block of content) {
    if (block.type !== "text" || !block.text) continue;
    textParts.push(block.text);
    for (const citation of block.citations ?? []) {
      if (citation.url && !sources.has(citation.url)) {
        sources.set(citation.url, citation.title ?? citation.url);
      }
    }
  }

  let reply = textParts.join("").trim();
  if (sources.size > 0) {
    const list = [...sources.entries()]
      .map(([url, title]) => `- ${title}: ${url}`)
      .join("\n");
    reply += `\n\nSources:\n${list}`;
  }
  return reply;
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
        tools: [
          { type: "web_search_20260318", name: "web_search", max_uses: 5 },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      return jsonResponse({ error: `Anthropic API error: ${errorText}` }, 502);
    }

    const data = await response.json();
    const reply = extractReply(data.content ?? []);

    return jsonResponse({ reply });
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});
