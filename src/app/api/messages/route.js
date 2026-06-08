import { auth } from "@/auth";
import sql from "@/app/api/utils/sql";

// POST /api/messages - Send a message
export async function POST(request) {
  const session = await auth();
  if (!session?.user?.id) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = session.user.id;

  try {
    const { conversationId, content } = await request.json();

    if (!conversationId || !content) {
      return Response.json(
        { error: "conversationId and content are required" },
        { status: 400 },
      );
    }

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

    // Create message
    const [message] = await sql`
      INSERT INTO messages (conversation_id, sender_id, content)
      VALUES (${conversationId}, ${userId}, ${content})
      RETURNING *
    `;

    // Update conversation last_message_at
    await sql`
      UPDATE conversations
      SET last_message_at = NOW()
      WHERE id = ${conversationId}
    `;

    return Response.json({ message });
  } catch (error) {
    console.error("Error sending message:", error);
    return Response.json({ error: "Failed to send message" }, { status: 500 });
  }
}
