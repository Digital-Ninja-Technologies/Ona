import sql from "@/app/api/utils/sql";
import crypto from "crypto";

export async function POST(request) {
  try {
    const { email } = await request.json();

    if (!email) {
      return Response.json({ error: "Email is required" }, { status: 400 });
    }

    // Check if user exists
    const users = await sql`
      SELECT id, email, name FROM auth_users WHERE email = ${email.toLowerCase().trim()}
    `;

    if (users.length === 0) {
      // For security, don't reveal if email exists
      // Still return success to prevent email enumeration
      return Response.json({
        message:
          "If an account exists with this email, you will receive a password reset link.",
      });
    }

    const user = users[0];

    // Generate secure token
    const token = crypto.randomBytes(32).toString("hex");

    // Set expiration to 1 hour from now
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1);

    // Store token in database
    await sql`
      INSERT INTO password_reset_tokens (token, user_id, expires_at)
      VALUES (${token}, ${user.id}, ${expiresAt})
    `;

    // Create reset link - use deep link for mobile app
    const resetLink = `globemate://reset-password?token=${token}`;
    const webResetLink = `${process.env.APP_URL}/reset-password?token=${token}`;

    // Log both links for testing
    console.log("=====================================");
    console.log("PASSWORD RESET REQUESTED");
    console.log("=====================================");
    console.log("User:", user.email);
    console.log("Name:", user.name);
    console.log("Mobile Reset Link:", resetLink);
    console.log("Web Reset Link:", webResetLink);
    console.log("Token:", token);
    console.log("Expires:", expiresAt.toISOString());
    console.log("=====================================");

    // TODO: Integrate with email service (Resend)
    // For now, the link is logged to console
    // In production, you should send an actual email

    return Response.json({
      message:
        "If an account exists with this email, you will receive a password reset link.",
      // Include token in development for testing
      ...(process.env.NODE_ENV === "development" && {
        token,
        resetLink,
        webResetLink,
      }),
    });
  } catch (error) {
    console.error("Request password reset error:", error);
    return Response.json({ error: "Internal server error" }, { status: 500 });
  }
}
