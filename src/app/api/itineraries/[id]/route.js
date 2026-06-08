import sql from "@/app/api/utils/sql";
import { auth } from "@/auth";

export async function GET(request, { params }) {
  try {
    const { id } = params;

    const [itinerary, items] = await sql.transaction([
      sql`
        SELECT i.*, d.name as destination_name, d.image_url as destination_image
        FROM itineraries i
        LEFT JOIN destinations d ON i.destination_id = d.id
        WHERE i.id = ${id}
      `,
      sql`
        SELECT ii.*, a.name as attraction_name, a.image_url as attraction_image,
               a.description as attraction_description
        FROM itinerary_items ii
        LEFT JOIN attractions a ON ii.attraction_id = a.id
        WHERE ii.itinerary_id = ${id}
        ORDER BY ii.day_number, ii.order_index
      `,
    ]);

    if (!itinerary || itinerary.length === 0) {
      return Response.json({ error: "Itinerary not found" }, { status: 404 });
    }

    return Response.json({
      itinerary: itinerary[0],
      items: items || [],
    });
  } catch (error) {
    console.error("Error fetching itinerary:", error);
    return Response.json(
      { error: "Failed to fetch itinerary" },
      { status: 500 },
    );
  }
}

export async function PUT(request, { params }) {
  try {
    const { id } = params;
    const body = await request.json();

    const updateFields = [];
    const values = [];
    let paramIndex = 1;

    const allowedFields = [
      "title",
      "description",
      "start_date",
      "end_date",
      "duration_days",
      "budget_total",
    ];

    for (const field of allowedFields) {
      if (body[field] !== undefined) {
        updateFields.push(`${field} = $${paramIndex}`);
        values.push(body[field]);
        paramIndex++;
      }
    }

    if (updateFields.length === 0) {
      return Response.json({ error: "No fields to update" }, { status: 400 });
    }

    values.push(id);
    const queryString = `
      UPDATE itineraries
      SET ${updateFields.join(", ")}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await sql(queryString, values);

    if (!result || result.length === 0) {
      return Response.json({ error: "Itinerary not found" }, { status: 404 });
    }

    return Response.json({ itinerary: result[0] });
  } catch (error) {
    console.error("Error updating itinerary:", error);
    return Response.json(
      { error: "Failed to update itinerary" },
      { status: 500 },
    );
  }
}

export async function DELETE(request, { params }) {
  try {
    const session = await auth();
    const userId = session?.user?.id;

    if (!userId) {
      return Response.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { id } = params;

    // Verify ownership before deleting
    const itinerary = await sql`
      SELECT user_id FROM itineraries WHERE id = ${id}
    `;

    if (!itinerary || itinerary.length === 0) {
      return Response.json({ error: "Itinerary not found" }, { status: 404 });
    }

    if (itinerary[0].user_id !== userId) {
      return Response.json({ error: "Forbidden" }, { status: 403 });
    }

    const result = await sql`
      DELETE FROM itineraries WHERE id = ${id} RETURNING *
    `;

    if (!result || result.length === 0) {
      return Response.json({ error: "Itinerary not found" }, { status: 404 });
    }

    return Response.json({ message: "Itinerary deleted successfully" });
  } catch (error) {
    console.error("Error deleting itinerary:", error);
    return Response.json(
      { error: "Failed to delete itinerary" },
      { status: 500 },
    );
  }
}
