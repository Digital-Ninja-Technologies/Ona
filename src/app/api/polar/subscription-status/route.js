import sql from "@/app/api/utils/sql";
import { auth } from "@/auth";

export async function GET(request) {
  try {
    const session = await auth();

    if (!session?.user?.email) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!process.env.POLAR_ACCESS_TOKEN) {
      return new Response(
        JSON.stringify({ error: "Polar.sh not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Get user from database
    const users = await sql`
      SELECT is_premium, premium_tier, premium_expires_at
      FROM users
      WHERE email = ${session.user.email}
    `;

    if (users.length === 0) {
      return new Response(JSON.stringify({ isPremium: false }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const user = users[0];

    // Fetch subscription details from Polar
    const subscriptionsResponse = await fetch(
      `https://api.polar.sh/v1/subscriptions/?customer_email=${encodeURIComponent(session.user.email)}`,
      {
        headers: {
          Authorization: `Bearer ${process.env.POLAR_ACCESS_TOKEN}`,
          "Content-Type": "application/json",
        },
      },
    );

    let activeSubscription = null;

    if (subscriptionsResponse.ok) {
      const data = await subscriptionsResponse.json();
      const subscriptions = data.items || [];

      activeSubscription = subscriptions.find(
        (sub) => sub.status === "active" || sub.status === "trialing",
      );
    }

    return new Response(
      JSON.stringify({
        isPremium: user.is_premium,
        tier: user.premium_tier,
        expiresAt: user.premium_expires_at,
        subscription: activeSubscription
          ? {
              id: activeSubscription.id,
              status: activeSubscription.status,
              currentPeriodEnd: activeSubscription.current_period_end,
              cancelAtPeriodEnd: activeSubscription.cancel_at_period_end,
              product: activeSubscription.product?.name,
            }
          : null,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Polar subscription status error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}
