import { auth } from "@/auth";
import sql from "@/app/api/utils/sql";

// GET /api/conversations/[id] - Get messages for a conversation
export async function GET(request, { params }) {
  const session = await auth();
  if (!session?.user?.id) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = session.user.id;
  const conversationId = params.id;

  try {
    // Verify user is part of this conversation
    const [conversation] = await sql`
      SELECT * FROM conversations
      WHERE id = ${conversationId}
      AND (user1_id = ${userId} OR user2_id = ${userId})
    `;

    if (!conversation) {
      return Response.json(
        { error: "Conversation not found" },
        { status: 404 },
      );
    }

    // Get messages
    const messages = await sql`
      SELECT 
        m.id,
        m.conversation_id,
        m.sender_id,
        m.content,
        m.is_read,
        m.created_at,
        u.name as sender_name,
        u.profile_image as sender_image
      FROM messages m
      LEFT JOIN users u ON m.sender_id = u.id
      WHERE m.conversation_id = ${conversationId}
      ORDER BY m.created_at ASC
    `;

    // Mark messages as read
    await sql`
      UPDATE messages
      SET is_read = true
      WHERE conversation_id = ${conversationId}
      AND sender_id != ${userId}
      AND is_read = false
    `;

    // Get other user info
    const otherUserId =
      conversation.user1_id === userId
        ? conversation.user2_id
        : conversation.user1_id;
    const [otherUser] = await sql`
      SELECT id, name, profile_image
      FROM users
      WHERE id = ${otherUserId}
    `;

    return Response.json({ messages, otherUser });
  } catch (error) {
    console.error("Error fetching messages:", error);
    return Response.json(
      { error: "Failed to fetch messages" },
      { status: 500 },
    );
  }
}
