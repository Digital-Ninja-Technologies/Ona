import sql from "@/app/api/utils/sql";

export async function POST(request) {
  try {
    const body = await request.json();
    const { type, data } = body;

    console.log("📥 Polar webhook received:", type);

    // Handle different webhook events
    switch (type) {
      case "checkout.completed":
        await handleCheckoutCompleted(data);
        break;

      case "subscription.created":
        await handleSubscriptionCreated(data);
        break;

      case "subscription.updated":
        await handleSubscriptionUpdated(data);
        break;

      case "subscription.canceled":
        await handleSubscriptionCanceled(data);
        break;

      case "subscription.revoked":
        await handleSubscriptionRevoked(data);
        break;

      default:
        console.log("Unhandled webhook type:", type);
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Polar webhook error:", error);
    return new Response(
      JSON.stringify({ error: "Webhook processing failed" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
}

async function handleCheckoutCompleted(data) {
  const { customer, subscription, product } = data;

  console.log("✅ Checkout completed for customer:", customer.email);

  // Find user by email
  const users = await sql`
    SELECT id FROM users WHERE email = ${customer.email}
  `;

  if (users.length === 0) {
    console.error("User not found for email:", customer.email);
    return;
  }

  const userId = users[0].id;

  // Determine subscription tier from product metadata
  const tier = determineTier(product);

  // Update user's premium status
  await sql`
    UPDATE users
    SET 
      is_premium = true,
      premium_tier = ${tier},
      premium_expires_at = ${subscription ? new Date(subscription.current_period_end) : null}
    WHERE id = ${userId}
  `;

  console.log("✅ User premium status updated:", userId);
}

async function handleSubscriptionCreated(data) {
  const { customer, current_period_end, product_id } = data;

  console.log("🎫 Subscription created for:", customer.email);

  const users = await sql`
    SELECT id FROM users WHERE email = ${customer.email}
  `;

  if (users.length === 0) return;

  const userId = users[0].id;

  await sql`
    UPDATE users
    SET 
      is_premium = true,
      premium_expires_at = ${new Date(current_period_end)}
    WHERE id = ${userId}
  `;
}

async function handleSubscriptionUpdated(data) {
  const { customer, current_period_end, status } = data;

  console.log("🔄 Subscription updated for:", customer.email);

  const users = await sql`
    SELECT id FROM users WHERE email = ${customer.email}
  `;

  if (users.length === 0) return;

  const userId = users[0].id;

  const isPremium = status === "active" || status === "trialing";

  await sql`
    UPDATE users
    SET 
      is_premium = ${isPremium},
      premium_expires_at = ${isPremium ? new Date(current_period_end) : null}
    WHERE id = ${userId}
  `;
}

async function handleSubscriptionCanceled(data) {
  const { customer } = data;

  console.log("❌ Subscription canceled for:", customer.email);

  const users = await sql`
    SELECT id FROM users WHERE email = ${customer.email}
  `;

  if (users.length === 0) return;

  const userId = users[0].id;

  // Note: With cancel_at_period_end, user keeps access until period ends
  // The subscription.updated webhook will handle the final deactivation
  console.log("User will retain access until period ends");
}

async function handleSubscriptionRevoked(data) {
  const { customer } = data;

  console.log("🚫 Subscription revoked for:", customer.email);

  const users = await sql`
    SELECT id FROM users WHERE email = ${customer.email}
  `;

  if (users.length === 0) return;

  const userId = users[0].id;

  await sql`
    UPDATE users
    SET 
      is_premium = false,
      premium_tier = null,
      premium_expires_at = null
    WHERE id = ${userId}
  `;
}

function determineTier(product) {
  // Extract tier from product name or metadata
  const name = product.name?.toLowerCase() || "";

  if (name.includes("yearly") || name.includes("annual")) {
    return "yearly";
  } else if (name.includes("lifetime")) {
    return "lifetime";
  } else {
    return "monthly";
  }
}
