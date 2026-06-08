import sql from "@/app/api/utils/sql";
import { auth } from "@/auth";

export async function GET(request) {
  try {
    const session = await auth();
    const userId = session?.user?.id;

    if (!userId) {
      // Return empty array if not authenticated instead of error
      return Response.json({ itineraries: [] });
    }

    const itineraries = await sql`
      SELECT i.*, d.name as destination_name, d.image_url as destination_image
      FROM itineraries i
      LEFT JOIN destinations d ON i.destination_id = d.id
      WHERE i.user_id = ${userId}
      ORDER BY i.created_at DESC
    `;

    return Response.json({ itineraries });
  } catch (error) {
    console.error("Error fetching itineraries:", error);
    return Response.json(
      { error: "Failed to fetch itineraries" },
      { status: 500 },
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const {
      userId,
      destinationId,
      title,
      description,
      startDate,
      endDate,
      durationDays,
      budgetTotal,
      isAiGenerated,
    } = body;

    if (!userId || !title || !durationDays) {
      return Response.json(
        { error: "Missing required fields" },
        { status: 400 },
      );
    }

    const result = await sql`
      INSERT INTO itineraries (
        user_id, destination_id, title, description, start_date,
        end_date, duration_days, budget_total, is_ai_generated
      )
      VALUES (
        ${userId}, ${destinationId || null}, ${title}, ${description || null},
        ${startDate || null}, ${endDate || null}, ${durationDays},
        ${budgetTotal || null}, ${isAiGenerated || false}
      )
      RETURNING *
    `;

    return Response.json({ itinerary: result[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating itinerary:", error);
    return Response.json(
      { error: "Failed to create itinerary" },
      { status: 500 },
    );
  }
}
