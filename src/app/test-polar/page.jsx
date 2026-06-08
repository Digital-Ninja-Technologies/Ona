"use client";

import { useState, useEffect } from "react";
import useUser from "@/utils/useUser";

export default function TestPolarPage() {
  const { data: user } = useUser();
  const [products, setProducts] = useState([]);
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProducts();
    fetchStatus();
  }, []);

  const fetchProducts = async () => {
    try {
      const response = await fetch("/api/polar/products");
      const data = await response.json();

      if (response.ok) {
        setProducts(data.products || []);
      } else {
        setError(data.error || "Failed to fetch products");
      }
    } catch (err) {
      console.error("Products fetch error:", err);
      setError("Network error fetching products");
    }
  };

  const fetchStatus = async () => {
    try {
      const response = await fetch("/api/polar/subscription-status");
      const data = await response.json();

      if (response.ok) {
        setStatus(data);
      }
    } catch (err) {
      console.error("Status fetch error:", err);
    }
  };

  const handleCheckout = async (productId) => {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch("/api/polar/create-checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productId,
          customerEmail: user?.email,
          successUrl: window.location.origin + "/test-polar?success=true",
        }),
      });

      const data = await response.json();

      if (response.ok && data.url) {
        window.location.href = data.url;
      } else {
        setError(data.error || "Failed to create checkout");
      }
    } catch (err) {
      console.error("Checkout error:", err);
      setError("Network error creating checkout");
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async () => {
    if (!status?.subscription?.id) return;

    const confirmed = confirm(
      "Are you sure you want to cancel your subscription? You will retain access until the end of your billing period.",
    );
    if (!confirmed) return;

    setLoading(true);
    try {
      const response = await fetch("/api/polar/cancel-subscription", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          subscriptionId: status.subscription.id,
        }),
      });

      const data = await response.json();

      if (response.ok) {
        alert(
          "Subscription cancelled. You will retain access until " +
            new Date(data.subscription.currentPeriodEnd).toLocaleDateString(),
        );
        fetchStatus();
      } else {
        alert(data.error || "Failed to cancel subscription");
      }
    } catch (err) {
      console.error("Cancel error:", err);
      alert("Network error cancelling subscription");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-black text-white p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">
          🧪 Polar.sh Integration Test
        </h1>
        <p className="text-gray-400 mb-8">
          Test your Polar subscription integration
        </p>

        {/* Current User */}
        <div className="bg-gray-800 rounded-lg p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">👤 Current User</h2>
          {user ? (
            <div>
              <p className="text-gray-300">
                Email:{" "}
                <span className="text-white font-mono">{user.email}</span>
              </p>
              <p className="text-gray-300">
                Name:{" "}
                <span className="text-white">{user.name || "Not set"}</span>
              </p>
            </div>
          ) : (
            <p className="text-yellow-400">
              ⚠️ Not logged in -{" "}
              <a href="/account/signin" className="underline">
                Sign in
              </a>
            </p>
          )}
        </div>

        {/* Subscription Status */}
        <div className="bg-gray-800 rounded-lg p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">📊 Subscription Status</h2>
          {status ? (
            <div className="space-y-2">
              <p className="text-gray-300">
                Premium:{" "}
                {status.isPremium ? (
                  <span className="text-green-400 font-semibold">
                    ✅ Active
                  </span>
                ) : (
                  <span className="text-gray-500">❌ Not Active</span>
                )}
              </p>
              {status.tier && (
                <p className="text-gray-300">
                  Tier:{" "}
                  <span className="text-white capitalize">{status.tier}</span>
                </p>
              )}
              {status.expiresAt && (
                <p className="text-gray-300">
                  Expires:{" "}
                  <span className="text-white">
                    {new Date(status.expiresAt).toLocaleDateString()}
                  </span>
                </p>
              )}
              {status.subscription && (
                <div className="mt-4 p-4 bg-gray-700 rounded">
                  <p className="font-semibold text-sm text-gray-400 mb-2">
                    Active Subscription
                  </p>
                  <p className="text-sm text-gray-300">
                    Product: {status.subscription.product}
                  </p>
                  <p className="text-sm text-gray-300">
                    Status:{" "}
                    <span className="capitalize">
                      {status.subscription.status}
                    </span>
                  </p>
                  <p className="text-sm text-gray-300">
                    Renews:{" "}
                    {new Date(
                      status.subscription.currentPeriodEnd,
                    ).toLocaleDateString()}
                  </p>
                  {status.subscription.cancelAtPeriodEnd && (
                    <p className="text-yellow-400 text-sm mt-2">
                      ⚠️ Scheduled to cancel at period end
                    </p>
                  )}
                  <button
                    onClick={handleCancel}
                    disabled={loading || status.subscription.cancelAtPeriodEnd}
                    className="mt-4 px-4 py-2 bg-red-600 hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white rounded text-sm"
                  >
                    {status.subscription.cancelAtPeriodEnd
                      ? "Already Scheduled to Cancel"
                      : "Cancel Subscription"}
                  </button>
                </div>
              )}
            </div>
          ) : (
            <p className="text-gray-400">Loading...</p>
          )}
        </div>

        {/* Available Products */}
        <div className="bg-gray-800 rounded-lg p-6">
          <h2 className="text-xl font-semibold mb-4">🛍️ Available Products</h2>

          {error && (
            <div className="bg-red-900/30 border border-red-500 rounded p-4 mb-4">
              <p className="text-red-400">❌ {error}</p>
            </div>
          )}

          {products.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-400 mb-4">No products found</p>
              <p className="text-sm text-gray-500">
                Create products in your Polar dashboard at{" "}
                <a
                  href="https://polar.sh/dashboard"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-400 underline"
                >
                  polar.sh/dashboard
                </a>
              </p>
            </div>
          ) : (
            <div className="grid gap-4">
              {products.map((product) => (
                <div
                  key={product.id}
                  className="bg-gray-700 rounded-lg p-6 border-2 border-cyan-500/30"
                >
                  <div className="flex justify-between items-start mb-4">
                    <div>
                      <h3 className="text-xl font-bold">{product.name}</h3>
                      <p className="text-gray-400 text-sm mt-1">
                        {product.description}
                      </p>
                    </div>
                    {product.prices && product.prices[0] && (
                      <div className="text-right">
                        <p className="text-2xl font-bold text-cyan-400">
                          ${(product.prices[0].amount / 100).toFixed(2)}
                        </p>
                        {product.recurringInterval && (
                          <p className="text-sm text-gray-400">
                            per {product.recurringInterval}
                          </p>
                        )}
                      </div>
                    )}
                  </div>

                  {product.benefits && product.benefits.length > 0 && (
                    <ul className="mb-4 space-y-1">
                      {product.benefits.map((benefit, idx) => (
                        <li
                          key={idx}
                          className="text-sm text-gray-300 flex items-start gap-2"
                        >
                          <span className="text-cyan-400">✓</span>
                          <span>{benefit}</span>
                        </li>
                      ))}
                    </ul>
                  )}

                  <button
                    onClick={() => handleCheckout(product.id)}
                    disabled={loading || !user}
                    className="w-full py-3 bg-cyan-500 hover:bg-cyan-600 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded transition"
                  >
                    {loading
                      ? "Processing..."
                      : user
                        ? "Subscribe Now"
                        : "Sign in to Subscribe"}
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Debug Info */}
        <div className="mt-6 bg-gray-800 rounded-lg p-6">
          <h2 className="text-xl font-semibold mb-4">🔧 Debug Info</h2>
          <div className="space-y-2 text-sm font-mono">
            <p className="text-gray-400">
              Webhook URL:{" "}
              <span className="text-white">
                {window.location.origin}/api/polar/webhooks
              </span>
            </p>
            <p className="text-gray-400">
              Products Endpoint:{" "}
              <span className="text-white">
                {window.location.origin}/api/polar/products
              </span>
            </p>
            <p className="text-gray-400">
              Status Endpoint:{" "}
              <span className="text-white">
                {window.location.origin}/api/polar/subscription-status
              </span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
