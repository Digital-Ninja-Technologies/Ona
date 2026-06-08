import sql from "@/app/api/utils/sql";

export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");

    if (!userId) {
      return Response.json({ error: "User ID required" }, { status: 400 });
    }

    const bookings = await sql`
      SELECT b.*, e.title as experience_title, e.image_url as experience_image,
             d.name as destination_name
      FROM bookings b
      LEFT JOIN experiences e ON b.experience_id = e.id
      LEFT JOIN destinations d ON e.destination_id = d.id
      WHERE b.user_id = ${userId}
      ORDER BY b.created_at DESC
    `;

    return Response.json({ bookings });
  } catch (error) {
    console.error("Error fetching bookings:", error);
    return Response.json(
      { error: "Failed to fetch bookings" },
      { status: 500 },
    );
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { userId, experienceId, bookingDate, numParticipants } = body;

    if (!userId || !experienceId || !bookingDate || !numParticipants) {
      return Response.json(
        { error: "Missing required fields" },
        { status: 400 },
      );
    }

    // Get experience details to calculate pricing
    const experience = await sql`
      SELECT * FROM experiences WHERE id = ${experienceId}
    `;

    if (!experience || experience.length === 0) {
      return Response.json({ error: "Experience not found" }, { status: 404 });
    }

    const totalPrice = parseFloat(experience[0].price) * numParticipants;
    const commissionRate = 0.15; // 15% commission
    const commissionAmount = totalPrice * commissionRate;

    const result = await sql`
      INSERT INTO bookings (
        user_id, experience_id, booking_date, num_participants,
        total_price, commission_amount, status
      )
      VALUES (
        ${userId}, ${experienceId}, ${bookingDate}, ${numParticipants},
        ${totalPrice}, ${commissionAmount}, 'pending'
      )
      RETURNING *
    `;

    // Update experience booking count
    await sql`
      UPDATE experiences
      SET total_bookings = total_bookings + 1
      WHERE id = ${experienceId}
    `;

    return Response.json({ booking: result[0] }, { status: 201 });
  } catch (error) {
    console.error("Error creating booking:", error);
    return Response.json(
      { error: "Failed to create booking" },
      { status: 500 },
    );
  }
}
