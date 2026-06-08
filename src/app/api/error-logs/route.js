import sql from "@/app/api/utils/sql";

export async function POST(request) {
  try {
    const body = await request.json();
    const {
      user_id,
      error_type,
      error_message,
      stack_trace,
      screen_name,
      platform,
      device_info,
      app_version,
    } = body;

    if (!error_message) {
      return Response.json(
        { error: "Error message is required" },
        { status: 400 },
      );
    }

    const result = await sql`
      INSERT INTO error_logs (
        user_id,
        error_type,
        error_message,
        stack_trace,
        screen_name,
        platform,
        device_info,
        app_version
      )
      VALUES (
        ${user_id || null},
        ${error_type || "Error"},
        ${error_message},
        ${stack_trace || ""},
        ${screen_name || null},
        ${platform || "web"},
        ${JSON.stringify(device_info || {})},
        ${app_version || "1.0.0"}
      )
      RETURNING id
    `;

    return Response.json({ success: true, id: result[0].id });
  } catch (error) {
    console.error("Error logging failed:", error);
    return Response.json({ error: "Failed to log error" }, { status: 500 });
  }
}

// Get error logs (admin only in production)
export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const resolved = searchParams.get("resolved");
    const days = parseInt(searchParams.get("days") || "7");

    let queryString = `
      SELECT 
        id,
        error_type,
        error_message,
        screen_name,
        platform,
        device_info,
        app_version,
        is_resolved,
        created_at,
        COUNT(*) OVER (PARTITION BY error_message) as occurrence_count
      FROM error_logs
      WHERE created_at >= NOW() - INTERVAL '${days} days'
    `;
    const params = [];

    if (resolved !== null) {
      queryString += ` AND is_resolved = $${params.length + 1}`;
      params.push(resolved === "true");
    }

    queryString += `
      ORDER BY created_at DESC
      LIMIT 100
    `;

    const results = await sql(queryString, params);

    return Response.json({ errors: results });
  } catch (error) {
    console.error("Get error logs failed:", error);
    return Response.json(
      { error: "Failed to retrieve error logs" },
      { status: 500 },
    );
  }
}
