export default function SignUpPage() {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-gradient-to-br from-pink-50 via-purple-50 to-indigo-50 p-4">
      <div className="w-full max-w-md rounded-3xl bg-white p-8 shadow-2xl text-center">
        <div className="mb-6">
          <svg
            className="mx-auto h-20 w-20 text-[#FF6B9D]"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
            />
          </svg>
        </div>

        <h1 className="font-fredoka mb-4 text-3xl font-medium text-gray-900">
          Mobile App Only
        </h1>

        <p className="font-nunito text-gray-600 mb-6">
          GlobeMate is a mobile application. Please download the app from the
          App Store or Google Play to create an account and start your travel
          journey.
        </p>

        <div className="flex flex-col gap-3">
          <a
            href="#"
            className="font-nunito rounded-xl bg-black px-6 py-3 text-white font-semibold hover:bg-gray-800 transition-colors"
          >
            Download on App Store
          </a>
          <a
            href="#"
            className="font-nunito rounded-xl bg-[#FF6B9D] px-6 py-3 text-white font-semibold hover:bg-[#E5528A] transition-colors"
          >
            Get it on Google Play
          </a>
        </div>
      </div>
    </div>
  );
}
