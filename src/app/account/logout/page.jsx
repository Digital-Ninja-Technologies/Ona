import useAuth from "@/utils/useAuth";

export default function LogoutPage() {
  const { signOut } = useAuth();

  const handleSignOut = async () => {
    await signOut({
      callbackUrl: "/",
      redirect: true,
    });
  };

  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-gradient-to-br from-pink-50 via-purple-50 to-indigo-50 p-4">
      <div className="w-full max-w-md rounded-3xl bg-white p-8 shadow-2xl">
        <div className="mb-8 text-center">
          <h1 className="font-fredoka mb-2 text-4xl font-medium text-gray-900">
            Sign Out
          </h1>
          <p className="font-nunito text-gray-600">
            Are you sure you want to leave?
          </p>
        </div>

        <button
          onClick={handleSignOut}
          className="font-nunito w-full rounded-xl bg-[#FF6B9D] px-4 py-3.5 text-base font-bold text-white shadow-lg shadow-[#FF6B9D]/30 transition-all hover:bg-[#E5528A] hover:shadow-xl"
        >
          Sign Out
        </button>

        <a
          href="/"
          className="font-nunito mt-4 block text-center text-sm font-semibold text-gray-600 hover:text-[#FF6B9D]"
        >
          Nevermind, take me back
        </a>
      </div>
    </div>
  );
}
