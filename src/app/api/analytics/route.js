import sql from "@/app/api/utils/sql";

export async function POST(request) {
  try {
    const body = await request.json();
    const {
      user_id,
      event_name,
      event_category,
      event_data,
      screen_name,
      platform,
      device_info,
    } = body;

    if (!event_name) {
      return Response.json(
        { error: "Event name is required" },
        { status: 400 },
      );
    }

    const result = await sql`
      INSERT INTO analytics_events (
        user_id,
        event_name,
        event_category,
        event_data,
        screen_name,
        platform,
        device_info
      )
      VALUES (
        ${user_id || null},
        ${event_name},
        ${event_category || "general"},
        ${JSON.stringify(event_data || {})},
        ${screen_name || null},
        ${platform || "web"},
        ${JSON.stringify(device_info || {})}
      )
      RETURNING id
    `;

    return Response.json({ success: true, id: result[0].id });
  } catch (error) {
    console.error("Analytics error:", error);
    return Response.json(
      { error: "Failed to log analytics event" },
      { status: 500 },
    );
  }
}

// Get analytics data (admin only in production)
export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const eventName = searchParams.get("event_name");
    const category = searchParams.get("category");
    const days = parseInt(searchParams.get("days") || "7");

    let queryString = `
      SELECT 
        event_name,
        event_category,
        COUNT(*) as event_count,
        COUNT(DISTINCT user_id) as unique_users,
        DATE(created_at) as event_date
      FROM analytics_events
      WHERE created_at >= NOW() - INTERVAL '${days} days'
    `;
    const params = [];

    if (eventName) {
      queryString += ` AND event_name = $${params.length + 1}`;
      params.push(eventName);
    }

    if (category) {
      queryString += ` AND event_category = $${params.length + 1}`;
      params.push(category);
    }

    queryString += `
      GROUP BY event_name, event_category, DATE(created_at)
      ORDER BY event_date DESC, event_count DESC
      LIMIT 100
    `;

    const results = await sql(queryString, params);

    return Response.json({ analytics: results });
  } catch (error) {
    console.error("Get analytics error:", error);
    return Response.json(
      { error: "Failed to retrieve analytics" },
      { status: 500 },
    );
  }
}
