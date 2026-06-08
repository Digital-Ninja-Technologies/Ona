export async function POST(request) {
  try {
    const body = await request.json();
    const { destinationName, durationDays, budget, interests } = body;

    if (!destinationName || !durationDays) {
      return Response.json(
        { error: "Destination and duration required" },
        { status: 400 },
      );
    }

    const prompt = `Create a detailed ${durationDays}-day travel itinerary for ${destinationName}.
    ${budget ? `Budget: ${budget}` : ""}
    ${interests && interests.length > 0 ? `Traveler interests: ${interests.join(", ")}` : ""}
    
    Format your response as a structured itinerary with:
    - A compelling title
    - Day-by-day breakdown with morning, afternoon, and evening activities
    - Specific attraction/restaurant/activity recommendations
    - Estimated costs where relevant
    - Practical travel tips
    
    Make it practical, engaging, and tailored to the traveler's preferences.`;

    const aiResponse = await fetch("/integrations/chat-gpt/conversationgpt4", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        messages: [
          {
            role: "system",
            content:
              "You are an expert travel planner. Create detailed, practical, and personalized travel itineraries.",
          },
          {
            role: "user",
            content: prompt,
          },
        ],
      }),
    });

    if (!aiResponse.ok) {
      throw new Error("Failed to generate itinerary with AI");
    }

    const aiData = await aiResponse.json();

    return Response.json({
      itinerary: aiData.choices[0].message.content,
    });
  } catch (error) {
    console.error("Error generating itinerary:", error);
    return Response.json(
      { error: "Failed to generate itinerary" },
      { status: 500 },
    );
  }
}
