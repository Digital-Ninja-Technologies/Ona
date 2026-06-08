import { auth } from "@/auth";

export async function POST(request) {
  try {
    const session = await auth();

    if (!session?.user?.email) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await request.json();
    const { subscriptionId } = body;

    if (!subscriptionId) {
      return new Response(
        JSON.stringify({ error: "Subscription ID required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!process.env.POLAR_ACCESS_TOKEN) {
      return new Response(
        JSON.stringify({ error: "Polar.sh not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Cancel subscription with Polar
    const cancelResponse = await fetch(
      `https://api.polar.sh/v1/subscriptions/${subscriptionId}`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${process.env.POLAR_ACCESS_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cancel_at_period_end: true,
        }),
      },
    );

    if (!cancelResponse.ok) {
      const error = await cancelResponse.text();
      console.error("Polar cancel error:", error);
      return new Response(
        JSON.stringify({ error: "Failed to cancel subscription" }),
        {
          status: cancelResponse.status,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const subscription = await cancelResponse.json();

    return new Response(
      JSON.stringify({
        success: true,
        subscription: {
          id: subscription.id,
          cancelAtPeriodEnd: subscription.cancel_at_period_end,
          currentPeriodEnd: subscription.current_period_end,
        },
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Polar cancel subscription error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}
