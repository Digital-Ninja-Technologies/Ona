export async function GET(request) {
  try {
    if (!process.env.POLAR_ACCESS_TOKEN) {
      return new Response(
        JSON.stringify({ error: "Polar.sh not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Fetch products from Polar
    const productsResponse = await fetch(
      "https://api.polar.sh/v1/products/?is_archived=false",
      {
        headers: {
          Authorization: `Bearer ${process.env.POLAR_ACCESS_TOKEN}`,
          "Content-Type": "application/json",
        },
      },
    );

    if (!productsResponse.ok) {
      const error = await productsResponse.text();
      console.error("Polar products fetch error:", error);
      return new Response(
        JSON.stringify({ error: "Failed to fetch products" }),
        {
          status: productsResponse.status,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const data = await productsResponse.json();

    // Transform products to a format suitable for the app
    const products = (data.items || []).map((product) => ({
      id: product.id,
      name: product.name,
      description: product.description,
      isRecurring: product.is_recurring,
      recurringInterval: product.recurring_interval,
      prices: product.prices?.map((price) => ({
        id: price.id,
        amount: price.price_amount,
        currency: price.price_currency,
        type: price.amount_type,
      })),
      benefits: product.benefits?.map((benefit) => benefit.description),
    }));

    return new Response(JSON.stringify({ products }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Polar products error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}
