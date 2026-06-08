import sql from "@/app/api/utils/sql";

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get("category");
    const search = searchParams.get("search");
    const limit = parseInt(searchParams.get("limit")) || 20;

    let query;
    let params = [];

    if (search) {
      // Search functionality with prioritization for country matches
      if (category && category !== "all") {
        query = `
          SELECT * FROM destinations
          WHERE $1 = ANY(category)
          AND (
            LOWER(name) LIKE LOWER($2)
            OR LOWER(city) LIKE LOWER($2)
            OR LOWER(country) LIKE LOWER($2)
            OR LOWER(description) LIKE LOWER($2)
          )
          ORDER BY 
            CASE 
              WHEN LOWER(country) = LOWER($3) THEN 1
              WHEN LOWER(country) LIKE LOWER($2) THEN 2
              WHEN LOWER(name) LIKE LOWER($2) THEN 3
              ELSE 4
            END,
            rating DESC
          LIMIT $4
        `;
        params = [category, `%${search}%`, search.trim(), limit];
      } else {
        query = `
          SELECT * FROM destinations
          WHERE LOWER(name) LIKE LOWER($1)
          OR LOWER(city) LIKE LOWER($1)
          OR LOWER(country) LIKE LOWER($1)
          OR LOWER(description) LIKE LOWER($1)
          ORDER BY 
            CASE 
              WHEN LOWER(country) = LOWER($2) THEN 1
              WHEN LOWER(country) LIKE LOWER($1) THEN 2
              WHEN LOWER(name) LIKE LOWER($1) THEN 3
              ELSE 4
            END,
            rating DESC
          LIMIT $3
        `;
        params = [`%${search}%`, search.trim(), limit];
      }
    } else if (category && category !== "all") {
      query = `
        SELECT * FROM destinations
        WHERE $1 = ANY(category)
        ORDER BY rating DESC
        LIMIT $2
      `;
      params = [category, limit];
    } else {
      query = `
        SELECT * FROM destinations
        ORDER BY rating DESC
        LIMIT $1
      `;
      params = [limit];
    }

    const destinations = await sql(query, params);

    return Response.json({
      destinations,
      success: true,
    });
  } catch (error) {
    console.error("Error fetching destinations:", error);
    return Response.json(
      { error: "Failed to fetch destinations" },
      { status: 500 },
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const {
      name,
      country,
      city,
      destinationType,
      description,
      imageUrl,
      latitude,
      longitude,
      category,
      rating,
      priceRange,
      bestTimeToVisit,
      popularActivities,
    } = body;

    const result = await sql`
      INSERT INTO destinations (
        name, country, city, destination_type, description, image_url,
        latitude, longitude, category, rating, price_range,
        best_time_to_visit, popular_activities
      )
      VALUES (
        ${name}, ${country}, ${city || null}, ${destinationType || "city"},
        ${description}, ${imageUrl}, ${latitude || null}, ${longitude || null},
        ${category || []}, ${rating || 4.5}, ${priceRange || "$$"},
        ${bestTimeToVisit || null}, ${popularActivities || []}
      )
      RETURNING *
    `;

    return Response.json({
      destination: result[0],
      success: true,
    });
  } catch (error) {
    console.error("Error creating destination:", error);
    return Response.json(
      { error: "Failed to create destination" },
      { status: 500 },
    );
  }
}
