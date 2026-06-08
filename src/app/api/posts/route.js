import sql from "@/app/api/utils/sql";

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");
    const destinationId = searchParams.get("destinationId");
    const postType = searchParams.get("type");
    const limit = parseInt(searchParams.get("limit") || "20");

    let queryString = `
      SELECT p.*, u.name as user_name, u.profile_image,
             d.name as destination_name
      FROM posts p
      LEFT JOIN users u ON p.user_id = u.id
      LEFT JOIN destinations d ON p.destination_id = d.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (userId) {
      queryString += ` AND p.user_id = $${paramIndex}`;
      params.push(userId);
      paramIndex++;
    }

    if (destinationId) {
      queryString += ` AND p.destination_id = $${paramIndex}`;
      params.push(destinationId);
      paramIndex++;
    }

    if (postType) {
      queryString += ` AND p.post_type = $${paramIndex}`;
      params.push(postType);
      paramIndex++;
    }

    queryString += ` ORDER BY p.created_at DESC LIMIT $${paramIndex}`;
    params.push(limit);

    const posts = await sql(queryString, params);

    return Response.json({ posts });
  } catch (error) {
    console.error("Error fetching posts:", error);
    return Response.json({ error: "Failed to fetch posts" }, { status: 500 });
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { userId, destinationId, title, content, images, postType } = body;

    if (!userId || !content || !postType) {
      return Response.json(
        { error: "Missing required fields" },
        { status: 400 },
      );
    }

    const result = await sql`
      INSERT INTO posts (
        user_id, destination_id, title, content, images, post_type
      )
      VALUES (
        ${userId}, ${destinationId || null}, ${title || null},
        ${content}, ${images || null}, ${postType}
      )
      RETURNING *
    `;

    return Response.json({ post: result[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating post:", error);
    return Response.json({ error: "Failed to create post" }, { status: 500 });
  }
}
