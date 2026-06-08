import sql from "@/app/api/utils/sql";

export async function POST(request) {
  try {
    const body = await request.json();
    const { agent_id, user_id, rating, comment, trip_date } = body;

    if (!agent_id || !user_id || !rating) {
      return Response.json(
        { error: "agent_id, user_id, and rating are required" },
        { status: 400 },
      );
    }

    if (rating < 1 || rating > 5) {
      return Response.json(
        { error: "Rating must be between 1 and 5" },
        { status: 400 },
      );
    }

    // Insert the review
    const review = await sql(
      `INSERT INTO agent_reviews (agent_id, user_id, rating, comment, trip_date)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [agent_id, user_id, rating, comment || null, trip_date || null],
    );

    // Update agent's average rating and total reviews
    await sql(
      `UPDATE travel_agents 
       SET rating = (
         SELECT AVG(rating)::NUMERIC(3,2) 
         FROM agent_reviews 
         WHERE agent_id = $1
       ),
       total_reviews = (
         SELECT COUNT(*) 
         FROM agent_reviews 
         WHERE agent_id = $1
       )
       WHERE id = $1`,
      [agent_id],
    );

    return Response.json({ review: review[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating agent review:", error);
    return Response.json({ error: "Failed to create review" }, { status: 500 });
  }
}
