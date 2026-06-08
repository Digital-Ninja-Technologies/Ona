import sql from "@/app/api/utils/sql";

export async function GET(request, { params }) {
  try {
    const { id } = params;

    const agents = await sql(
      `SELECT 
        ta.*,
        u.name as contact_name,
        u.email as contact_email,
        u.profile_image as user_profile_image
       FROM travel_agents ta
       LEFT JOIN users u ON ta.user_id = u.id
       WHERE ta.id = $1`,
      [id],
    );

    if (agents.length === 0) {
      return Response.json({ error: "Agent not found" }, { status: 404 });
    }

    // Get reviews for this agent
    const reviews = await sql(
      `SELECT 
        ar.*,
        u.name as reviewer_name,
        u.profile_image as reviewer_image
       FROM agent_reviews ar
       LEFT JOIN users u ON ar.user_id = u.id
       WHERE ar.agent_id = $1
       ORDER BY ar.created_at DESC
       LIMIT 10`,
      [id],
    );

    return Response.json({
      agent: agents[0],
      reviews,
    });
  } catch (error) {
    console.error("Error fetching travel agent:", error);
    return Response.json(
      { error: "Failed to fetch travel agent" },
      { status: 500 },
    );
  }
}

export async function PATCH(request, { params }) {
  try {
    const { id } = params;
    const body = await request.json();

    const updates = [];
    const values = [];
    let paramIndex = 1;

    const allowedFields = [
      "business_name",
      "bio",
      "profile_image",
      "specialties",
      "languages_spoken",
      "years_experience",
      "certifications",
      "countries_expertise",
      "pricing_tier",
      "response_time_hours",
      "is_available",
    ];

    for (const field of allowedFields) {
      if (body[field] !== undefined) {
        updates.push(`${field} = $${paramIndex}`);
        values.push(body[field]);
        paramIndex++;
      }
    }

    if (updates.length === 0) {
      return Response.json({ error: "No fields to update" }, { status: 400 });
    }

    values.push(id);
    const query = `UPDATE travel_agents SET ${updates.join(", ")} WHERE id = $${paramIndex} RETURNING *`;

    const result = await sql(query, values);

    if (result.length === 0) {
      return Response.json({ error: "Agent not found" }, { status: 404 });
    }

    return Response.json({ agent: result[0] });
  } catch (error) {
    console.error("Error updating travel agent:", error);
    return Response.json(
      { error: "Failed to update travel agent" },
      { status: 500 },
    );
  }
}
