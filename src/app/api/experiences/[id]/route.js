import sql from "@/app/api/utils/sql";

export async function GET(request, { params }) {
  try {
    const { id } = params;

    const [experience, reviews] = await sql.transaction([
      sql`
        SELECT e.*, d.name as destination_name, d.country
        FROM experiences e
        LEFT JOIN destinations d ON e.destination_id = d.id
        WHERE e.id = ${id}
      `,
      sql`
        SELECT r.*, u.name as user_name, u.profile_image
        FROM reviews r
        LEFT JOIN users u ON r.user_id = u.id
        WHERE r.experience_id = ${id}
        ORDER BY r.created_at DESC
      `,
    ]);

    if (!experience || experience.length === 0) {
      return Response.json({ error: "Experience not found" }, { status: 404 });
    }

    return Response.json({
      experience: experience[0],
      reviews: reviews || [],
    });
  } catch (error) {
    console.error("Error fetching experience:", error);
    return Response.json(
      { error: "Failed to fetch experience" },
      { status: 500 },
    );
  }
}
