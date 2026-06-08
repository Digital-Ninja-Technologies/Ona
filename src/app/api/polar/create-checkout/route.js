export async function POST(request) {
  try {
    const body = await request.json();
    const { productId, successUrl, customerEmail } = body;

    if (!process.env.POLAR_ACCESS_TOKEN) {
      return new Response(
        JSON.stringify({ error: "Polar.sh not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Create checkout session with Polar
    const checkoutResponse = await fetch("https://api.polar.sh/v1/checkouts/", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.POLAR_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        product_id: productId,
        success_url: successUrl,
        customer_email: customerEmail,
      }),
    });

    if (!checkoutResponse.ok) {
      const error = await checkoutResponse.text();
      console.error("Polar checkout error:", error);
      return new Response(
        JSON.stringify({
          error: "Failed to create checkout",
          details: error,
        }),
        {
          status: checkoutResponse.status,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const checkout = await checkoutResponse.json();

    return new Response(JSON.stringify(checkout), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Polar checkout creation error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
}
