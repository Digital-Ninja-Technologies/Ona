"use client";
import { useEffect } from "react";

export default function InterestsPage() {
  useEffect(() => {
    // Redirect to home - onboarding is mobile-only
    window.location.href = "/";
  }, []);

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-pink-50 via-purple-50 to-indigo-50">
      <div className="text-center">
        <p className="text-gray-600">Redirecting...</p>
      </div>
    </div>
  );
}
