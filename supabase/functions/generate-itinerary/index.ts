// Supabase Edge Function: generate-itinerary
//
// Asks Gemini (with a Groq fallback) for a structured day-by-day itinerary,
// reusing the same free-tier keys as the ai-assistant function — no
// separate API key needed.
// Deploy with:
//   supabase functions deploy generate-itinerary
//
// Request body:
//   { "destination": string, "days": number, "budget": "budget" | "moderate" | "luxury" }
// Response body:
//   { "title": string, "description": string, "days": [{ "day": number, "activities": string[] }] }

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.7-flash";
const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const GROQ_MODEL = Deno.env.get("GROQ_MODEL") ?? "openai/gpt-oss-120b";

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

/**
 * True if a failed Gemini response looks like something a retry to a
 * different provider would fix: a free-tier quota hit, or Gemini's own
 * infrastructure being overloaded/unavailable (5xx) — as opposed to e.g. a
 * 400 from a malformed request, which Groq would fail identically.
 */
function shouldFallBackToGroq(status: number, errorText: string): boolean {
  return (
    status === 429 ||
    status >= 500 ||
    /too_many_requests|RESOURCE_EXHAUSTED|quota|UNAVAILABLE/i.test(errorText)
  );
}

/** Fallback call to Groq's free tier when Gemini is rate-limited/unavailable. */
async function callGroq(prompt: string): Promise<string> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);

  let response: Response;
  try {
    response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [{ role: "user", content: prompt }],
      }),
      signal: controller.signal,
    });
  } catch (err) {
    throw new Error(
      controller.signal.aborted
        ? "Groq request timed out after 20s"
        : `Groq request failed: ${err}`,
    );
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Groq API error: ${errorText}`);
  }

  const data = await response.json();
  const text = data?.choices?.[0]?.message?.content;
  if (typeof text !== "string") {
    throw new Error("Unexpected response shape from Groq.");
  }
  return text;
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

    // Cap how long we wait on Gemini — see ai-assistant/index.ts for why.
    const geminiController = new AbortController();
    const geminiTimeout = setTimeout(() => geminiController.abort(), 20_000);

    let geminiResponse: Response | null = null;
    let geminiNetworkError: string | null = null;
    try {
      geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
        {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-goog-api-key": GEMINI_API_KEY,
          },
          body: JSON.stringify({
            contents: [{ role: "user", parts: [{ text: prompt }] }],
          }),
          signal: geminiController.signal,
        },
      );
    } catch (err) {
      geminiNetworkError = geminiController.signal.aborted
        ? "Gemini request timed out after 20s"
        : `Gemini request failed: ${err}`;
    } finally {
      clearTimeout(geminiTimeout);
    }

    let rawText: string;

    if (geminiResponse?.ok) {
      const data = await geminiResponse.json();
      const parts = data?.candidates?.[0]?.content?.parts;
      rawText = Array.isArray(parts)
        ? parts.map((part: { text?: string }) => part.text ?? "").join("")
        : "";
    } else {
      const errorText = geminiNetworkError ?? (await geminiResponse!.text());
      const shouldFallBack =
        geminiNetworkError !== null ||
        shouldFallBackToGroq(geminiResponse!.status, errorText);
      if (!GROQ_API_KEY || !shouldFallBack) {
        return jsonResponse({ error: `Gemini API error: ${errorText}` }, 502);
      }
      try {
        rawText = await callGroq(prompt);
      } catch (groqError) {
        return jsonResponse(
          {
            error:
              `Gemini unavailable (${errorText}); Groq fallback also ` +
              `failed: ${groqError}`,
          },
          502,
        );
      }
    }

    const start = rawText.indexOf("{");
    const end = rawText.lastIndexOf("}");
    const jsonText =
      start >= 0 && end >= start ? rawText.slice(start, end + 1) : "{}";

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
