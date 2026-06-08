import sql from "@/app/api/utils/sql";

export async function POST(request) {
  try {
    const body = await request.json();
    const { destinationId, userId = 1 } = body; // Mock user ID for now

    // Check if already saved
    const existing = await sql`
      SELECT * FROM saved_destinations
      WHERE user_id = ${userId} AND destination_id = ${destinationId}
    `;

    if (existing.length > 0) {
      // Remove from saved
      await sql`
        DELETE FROM saved_destinations
        WHERE user_id = ${userId} AND destination_id = ${destinationId}
      `;
      return Response.json({ saved: false, success: true });
    } else {
      // Add to saved
      await sql`
        INSERT INTO saved_destinations (user_id, destination_id)
        VALUES (${userId}, ${destinationId})
      `;
      return Response.json({ saved: true, success: true });
    }
  } catch (error) {
    console.error("Error saving destination:", error);
    return Response.json(
      { error: "Failed to save destination" },
      { status: 500 },
    );
  }
}

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId") || 1; // Mock user ID

    const saved = await sql`
      SELECT d.* FROM destinations d
      INNER JOIN saved_destinations sd ON d.id = sd.destination_id
      WHERE sd.user_id = ${userId}
      ORDER BY sd.created_at DESC
    `;

    return Response.json({
      destinations: saved,
      success: true,
    });
  } catch (error) {
    console.error("Error fetching saved destinations:", error);
    return Response.json(
      { error: "Failed to fetch saved destinations" },
      { status: 500 },
    );
  }
}
