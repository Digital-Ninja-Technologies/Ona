import sql from "@/app/api/utils/sql";

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get("limit")) || 20;
    const offset = parseInt(searchParams.get("offset")) || 0;
    const specialty = searchParams.get("specialty");
    const country = searchParams.get("country");
    const minRating = searchParams.get("minRating");

    let query = `
      SELECT 
        ta.*,
        u.name as contact_name,
        u.email as contact_email
      FROM travel_agents ta
      LEFT JOIN users u ON ta.user_id = u.id
      WHERE ta.is_available = true
    `;
    const params = [];
    let paramIndex = 1;

    if (specialty) {
      query += ` AND $${paramIndex} = ANY(ta.specialties)`;
      params.push(specialty);
      paramIndex++;
    }

    if (country) {
      query += ` AND $${paramIndex} = ANY(ta.countries_expertise)`;
      params.push(country);
      paramIndex++;
    }

    if (minRating) {
      query += ` AND ta.rating >= $${paramIndex}`;
      params.push(parseFloat(minRating));
      paramIndex++;
    }

    query += ` ORDER BY ta.rating DESC, ta.total_reviews DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const agents = await sql(query, params);

    return Response.json({
      agents,
      count: agents.length,
    });
  } catch (error) {
    console.error("Error fetching travel agents:", error);
    return Response.json(
      { error: "Failed to fetch travel agents" },
      { status: 500 },
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const {
      user_id,
      business_name,
      bio,
      profile_image,
      specialties,
      languages_spoken,
      years_experience,
      certifications,
      countries_expertise,
      pricing_tier,
      response_time_hours,
    } = body;

    if (!user_id || !business_name) {
      return Response.json(
        { error: "user_id and business_name are required" },
        { status: 400 },
      );
    }

    const result = await sql(
      `INSERT INTO travel_agents 
        (user_id, business_name, bio, profile_image, specialties, languages_spoken, 
         years_experience, certifications, countries_expertise, pricing_tier, response_time_hours)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        user_id,
        business_name,
        bio || null,
        profile_image || null,
        specialties || [],
        languages_spoken || [],
        years_experience || 0,
        certifications || [],
        countries_expertise || [],
        pricing_tier || "all",
        response_time_hours || 24,
      ],
    );

    return Response.json({ agent: result[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating travel agent:", error);
    return Response.json(
      { error: "Failed to create travel agent" },
      { status: 500 },
    );
  }
}
