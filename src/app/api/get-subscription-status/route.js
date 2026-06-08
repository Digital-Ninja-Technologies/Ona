import sql from "@/app/api/utils/sql";
import { auth } from "@/auth";

export const POST = async (request) => {
  async function handler() {
    // Get authenticated user
    const session = await auth();
    if (!session?.user) {
      return {
        status: "none",
        message: "Not authenticated",
      };
    }

    const email = session.user.email;

    try {
      if (!process.env.POLAR_ACCESS_TOKEN) {
        return {
          status: "none",
          message: "Polar.sh not configured",
        };
      }

      // Get user from database
      const users = await sql`
        SELECT is_premium, premium_tier, premium_expires_at
        FROM users
        WHERE email = ${email}
      `;

      if (users.length === 0) {
        return {
          status: "none",
          message: "User not found",
        };
      }

      const user = users[0];

      // Check if user has an active premium status in the database
      if (user.is_premium) {
        return {
          status: "active",
          tier: user.premium_tier,
          expiresAt: user.premium_expires_at,
        };
      }

      // Also check Polar API for active subscriptions
      const subscriptionsResponse = await fetch(
        `https://api.polar.sh/v1/subscriptions/?customer_email=${encodeURIComponent(email)}`,
        {
          headers: {
            Authorization: `Bearer ${process.env.POLAR_ACCESS_TOKEN}`,
            "Content-Type": "application/json",
          },
        },
      );

      if (subscriptionsResponse.ok) {
        const data = await subscriptionsResponse.json();
        const subscriptions = data.items || [];

        const activeSubscription = subscriptions.find(
          (sub) => sub.status === "active" || sub.status === "trialing",
        );

        if (activeSubscription) {
          return {
            status: "active",
            subscriptionId: activeSubscription.id,
          };
        }
      }

      return {
        status: "none",
        message: "No active subscription",
      };
    } catch (error) {
      console.error("Error checking subscription:", error);
      return {
        status: "error",
        message: error.message,
      };
    }
  }

  let data = {};
  try {
    data = await request.json();
  } catch {
    // no-op
  }

  const result = await handler(data, request);
  if (result instanceof Response) {
    return result;
  }
  return Response.json(result === undefined ? {} : result);
};
