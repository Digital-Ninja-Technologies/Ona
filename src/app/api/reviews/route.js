import sql from "@/app/api/utils/sql";

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const destinationId = searchParams.get("destinationId");
    const experienceId = searchParams.get("experienceId");

    let queryString = `
      SELECT r.*, u.name as user_name, u.profile_image
      FROM reviews r
      LEFT JOIN users u ON r.user_id = u.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (destinationId) {
      queryString += ` AND r.destination_id = $${paramIndex}`;
      params.push(destinationId);
      paramIndex++;
    }

    if (experienceId) {
      queryString += ` AND r.experience_id = $${paramIndex}`;
      params.push(experienceId);
      paramIndex++;
    }

    queryString += ` ORDER BY r.created_at DESC`;

    const reviews = await sql(queryString, params);

    return Response.json({ reviews });
  } catch (error) {
    console.error("Error fetching reviews:", error);
    return Response.json({ error: "Failed to fetch reviews" }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { userId, destinationId, experienceId, rating, comment, images } =
      body;

    if (!userId || !rating) {
      return Response.json(
        { error: "Missing required fields" },
        { status: 400 },
      );
    }

    if (rating < 1 || rating > 5) {
      return Response.json({ error: "Rating must be 1-5" }, { status: 400 });
    }

    const result = await sql`
      INSERT INTO reviews (
        user_id, destination_id, experience_id, rating, comment, images
      )
      VALUES (
        ${userId}, ${destinationId || null}, ${experienceId || null},
        ${rating}, ${comment || null}, ${images || null}
      )
      RETURNING *
    `;

    return Response.json({ review: result[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating review:", error);
    return Response.json({ error: "Failed to create review" }, { status: 500 });
  }
}
