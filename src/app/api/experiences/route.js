import sql from "@/app/api/utils/sql";

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const destinationId = searchParams.get("destinationId");
    const category = searchParams.get("category");
    const limit = parseInt(searchParams.get("limit") || "20");
    const offset = parseInt(searchParams.get("offset") || "0");

    let queryString = `
      SELECT e.*, d.name as destination_name, d.country
      FROM experiences e
      LEFT JOIN destinations d ON e.destination_id = d.id
      WHERE e.is_approved = true
    `;
    const params = [];
    let paramIndex = 1;

    if (destinationId) {
      queryString += ` AND e.destination_id = $${paramIndex}`;
      params.push(destinationId);
      paramIndex++;
    }

    if (category) {
      queryString += ` AND e.category = $${paramIndex}`;
      params.push(category);
      paramIndex++;
    }

    queryString += ` ORDER BY e.rating DESC, e.total_bookings DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const experiences = await sql(queryString, params);

    return Response.json({ experiences });
  } catch (error) {
    console.error("Error fetching experiences:", error);
    return Response.json(
      { error: "Failed to fetch experiences" },
      { status: 500 },
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const {
      destinationId,
      vendorId,
      title,
      description,
      imageUrl,
      category,
      price,
      durationHours,
      maxParticipants,
    } = body;

    if (!destinationId || !vendorId || !title || !price) {
      return Response.json(
        { error: "Missing required fields" },
        { status: 400 },
      );
    }

    const result = await sql`
      INSERT INTO experiences (
        destination_id, vendor_id, title, description, image_url,
        category, price, duration_hours, max_participants
      )
      VALUES (
        ${destinationId}, ${vendorId}, ${title}, ${description || null},
        ${imageUrl || null}, ${category || null}, ${price},
        ${durationHours || null}, ${maxParticipants || null}
      )
      RETURNING *
    `;

    return Response.json({ experience: result[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating experience:", error);
    return Response.json(
      { error: "Failed to create experience" },
      { status: 500 },
    );
  }
}
