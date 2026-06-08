import sql from "@/app/api/utils/sql";
import { auth } from "@/auth";
import { decode } from "@auth/core/jwt";

// Helper to get user from session or JWT
async function getUserId(request) {
  // Try session first (web)
  const session = await auth();
  if (session?.user?.id) {
    return session.user.id;
  }

  // Try JWT from Authorization header (mobile)
  const authHeader = request.headers.get("authorization");
  if (authHeader?.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const decoded = await decode({
        token,
        secret: process.env.AUTH_SECRET,
      });
      if (decoded?.sub) {
        return parseInt(decoded.sub, 10);
      }
    } catch (err) {
      console.error("JWT decode error:", err);
    }
  }

  return null;
}

export async function GET(request) {
  try {
    const userId = await getUserId(request);
    if (!userId) {
      return Response.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Try to get from users table first
    const userRows = await sql`
      SELECT id, email, name, profile_image, preferred_destinations, 
             budget_range, interests, language_preference, is_premium, 
             premium_tier, premium_expires_at 
      FROM users 
      WHERE id = ${userId} 
      LIMIT 1
    `;

    if (userRows.length > 0) {
      return Response.json({ user: userRows[0] });
    }

    // If not in users table, get from auth_users
    const authRows = await sql`
      SELECT id, name, email, image 
      FROM auth_users 
      WHERE id = ${userId} 
      LIMIT 1
    `;

    if (authRows.length > 0) {
      return Response.json({
        user: {
          id: authRows[0].id,
          name: authRows[0].name,
          email: authRows[0].email,
          profile_image: authRows[0].image,
        },
      });
    }

    return Response.json({ error: "User not found" }, { status: 404 });
  } catch (err) {
    console.error("GET /api/users/profile error", err);
    return Response.json({ error: "Internal Server Error" }, { status: 500 });
  }
}

export async function PUT(request) {
  try {
    const userId = await getUserId(request);
    if (!userId) {
      return Response.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      interests,
      budget_range,
      preferred_destinations,
      name,
      profile_image,
    } = body || {};

    // Check if user exists in users table
    const existingUser = await sql`
      SELECT id FROM users WHERE id = ${userId} LIMIT 1
    `;

    if (existingUser.length === 0) {
      // Create user in users table
      const authUser = await sql`
        SELECT email, name, image FROM auth_users WHERE id = ${userId} LIMIT 1
      `;

      if (authUser.length === 0) {
        return Response.json({ error: "User not found" }, { status: 404 });
      }

      await sql`
        INSERT INTO users (id, email, name, profile_image, interests, budget_range, preferred_destinations)
        VALUES (
          ${userId},
          ${authUser[0].email},
          ${name || authUser[0].name},
          ${profile_image || authUser[0].image},
          ${interests || []},
          ${budget_range || "moderate"},
          ${preferred_destinations || []}
        )
      `;
    } else {
      // Update existing user
      const setClauses = [];
      const values = [];
      let paramIndex = 1;

      if (Array.isArray(interests)) {
        setClauses.push(`interests = $${paramIndex++}`);
        values.push(interests);
      }

      if (typeof budget_range === "string") {
        setClauses.push(`budget_range = $${paramIndex++}`);
        values.push(budget_range);
      }

      if (Array.isArray(preferred_destinations)) {
        setClauses.push(`preferred_destinations = $${paramIndex++}`);
        values.push(preferred_destinations);
      }

      if (typeof name === "string") {
        setClauses.push(`name = $${paramIndex++}`);
        values.push(name);
      }

      if (typeof profile_image === "string") {
        setClauses.push(`profile_image = $${paramIndex++}`);
        values.push(profile_image);
      }

      if (setClauses.length > 0) {
        values.push(userId);
        const query = `
          UPDATE users 
          SET ${setClauses.join(", ")} 
          WHERE id = $${paramIndex}
          RETURNING id, email, name, profile_image, preferred_destinations, 
                    budget_range, interests, language_preference, is_premium, 
                    premium_tier, premium_expires_at
        `;
        const result = await sql(query, values);
        return Response.json({ user: result[0] });
      }
    }

    // Fetch updated user
    const updatedUser = await sql`
      SELECT id, email, name, profile_image, preferred_destinations, 
             budget_range, interests, language_preference, is_premium, 
             premium_tier, premium_expires_at 
      FROM users 
      WHERE id = ${userId} 
      LIMIT 1
    `;

    return Response.json({ user: updatedUser[0] });
  } catch (err) {
    console.error("PUT /api/users/profile error", err);
    return Response.json({ error: "Internal Server Error" }, { status: 500 });
  }
}
