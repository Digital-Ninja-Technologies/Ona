import { auth } from "@/auth";
import { decode } from "@auth/core/jwt";

/**
 * Helper function to get authenticated user ID from either:
 * - Web session (NextAuth)
 * - Mobile JWT token (Authorization header)
 *
 * @param {Request} request - The incoming request object
 * @returns {Promise<number|null>} - The user ID or null if not authenticated
 */
export async function getUserId(request) {
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

/**
 * Helper function to require authentication, returns user ID or throws unauthorized response
 *
 * @param {Request} request - The incoming request object
 * @returns {Promise<number>} - The authenticated user ID
 * @throws {Response} - Unauthorized response if not authenticated
 */
export async function requireAuth(request) {
  const userId = await getUserId(request);
  if (!userId) {
    throw Response.json({ error: "Unauthorized" }, { status: 401 });
  }
  return userId;
}
