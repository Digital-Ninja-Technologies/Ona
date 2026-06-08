import { auth } from "@/auth";
import sql from "@/app/api/utils/sql";

// GET /api/conversations - Get all conversations for the current user
export async function GET(request) {
  const session = await auth();
  if (!session?.user?.id) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = session.user.id;

  try {
    const conversations = await sql`
      SELECT 
        c.id,
        c.last_message_at,
        c.created_at,
        CASE 
          WHEN c.user1_id = ${userId} THEN u2.id
          ELSE u1.id
        END as other_user_id,
        CASE 
          WHEN c.user1_id = ${userId} THEN u2.name
          ELSE u1.name
        END as other_user_name,
        CASE 
          WHEN c.user1_id = ${userId} THEN u2.profile_image
          ELSE u1.profile_image
        END as other_user_image,
        (
          SELECT content 
          FROM messages 
          WHERE conversation_id = c.id 
          ORDER BY created_at DESC 
          LIMIT 1
        ) as last_message,
        (
          SELECT sender_id 
          FROM messages 
          WHERE conversation_id = c.id 
          ORDER BY created_at DESC 
          LIMIT 1
        ) as last_message_sender_id,
        (
          SELECT COUNT(*) 
          FROM messages 
          WHERE conversation_id = c.id 
          AND sender_id != ${userId} 
          AND is_read = false
        )::int as unread_count
      FROM conversations c
      LEFT JOIN users u1 ON c.user1_id = u1.id
      LEFT JOIN users u2 ON c.user2_id = u2.id
      WHERE c.user1_id = ${userId} OR c.user2_id = ${userId}
      ORDER BY c.last_message_at DESC
    `;

    return Response.json({ conversations });
  } catch (error) {
    console.error("Error fetching conversations:", error);
    return Response.json(
      { error: "Failed to fetch conversations" },
      { status: 500 },
    );
  }
}

// POST /api/conversations - Create a new conversation
export async function POST(request) {
  const session = await auth();
  if (!session?.user?.id) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = session.user.id;

  try {
    const { otherUserId } = await request.json();

    if (!otherUserId) {
      return Response.json(
        { error: "otherUserId is required" },
        { status: 400 },
      );
    }

    // Check if conversation already exists (in either direction)
    const existing = await sql`
      SELECT id FROM conversations
      WHERE (user1_id = ${userId} AND user2_id = ${otherUserId})
         OR (user1_id = ${otherUserId} AND user2_id = ${userId})
    `;

    if (existing.length > 0) {
      return Response.json({ conversation: existing[0] });
    }

    // Create new conversation
    const [conversation] = await sql`
      INSERT INTO conversations (user1_id, user2_id)
      VALUES (${userId}, ${otherUserId})
      RETURNING *
    `;

    return Response.json({ conversation });
  } catch (error) {
    console.error("Error creating conversation:", error);
    return Response.json(
      { error: "Failed to create conversation" },
      { status: 500 },
    );
  }
}
