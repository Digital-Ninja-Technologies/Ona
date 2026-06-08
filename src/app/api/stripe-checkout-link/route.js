import Stripe from "stripe";
import { auth } from "@/auth";

export const POST = async (request) => {
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

  async function handler({ redirectURL, product }) {
    // Get authenticated user
    const session = await auth();
    if (!session?.user) {
      return Response.json({ error: "Unauthorized" }, { status: 401 });
    }

    const userId = session.user.id;
    const email = session.user.email;

    // Define pricing tiers
    const getPriceData = (productTier) => {
      switch (productTier) {
        case "monthly":
          return {
            currency: "usd",
            product_data: { name: "GlobeMate Premium - Monthly" },
            recurring: { interval: "month" },
            unit_amount: 999, // $9.99
          };
        case "yearly":
          return {
            currency: "usd",
            product_data: { name: "GlobeMate Premium - Yearly" },
            recurring: { interval: "year" },
            unit_amount: 9900, // $99.00 (save 17%)
          };
        case "lifetime":
          return {
            currency: "usd",
            product_data: { name: "GlobeMate Premium - Lifetime" },
            unit_amount: 29900, // $299.00
          };
        default:
          return {
            currency: "usd",
            product_data: { name: "GlobeMate Premium - Monthly" },
            recurring: { interval: "month" },
            unit_amount: 999,
          };
      }
    };

    const priceData = getPriceData(product || "monthly");
    const mode = product === "lifetime" ? "payment" : "subscription";

    try {
      // Create or get customer
      const customers = await stripe.customers.list({
        email: email,
        limit: 1,
      });

      let stripeCustomerId;
      if (customers.data.length > 0) {
        stripeCustomerId = customers.data[0].id;
      } else {
        const customer = await stripe.customers.create({ email });
        stripeCustomerId = customer.id;
      }

      // Create checkout session
      const session = await stripe.checkout.sessions.create({
        customer: stripeCustomerId,
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: priceData,
            quantity: 1,
          },
        ],
        mode: mode,
        success_url: `${redirectURL}?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: redirectURL,
      });

      return { url: session.url };
    } catch (error) {
      console.error("Stripe checkout error:", error);
      return Response.json(
        { error: "Failed to create checkout session" },
        { status: 500 },
      );
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
