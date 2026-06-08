import { hash, verify } from "argon2";
import sql from "@/app/api/utils/sql";

export async function GET(request) {
  const tests = {
    database: false,
    argon2: false,
    authSecret: false,
  };
  const errors = [];

  // Test 1: Database connection
  try {
    await sql`SELECT 1`;
    tests.database = true;
  } catch (error) {
    errors.push(`Database: ${error.message}`);
  }

  // Test 2: Argon2 hashing
  try {
    const testHash = await hash("test123");
    const testVerify = await verify(testHash, "test123");
    if (testVerify) {
      tests.argon2 = true;
    } else {
      errors.push("Argon2: Hash verification failed");
    }
  } catch (error) {
    errors.push(`Argon2: ${error.message}`);
  }

  // Test 3: AUTH_SECRET
  if (process.env.AUTH_SECRET) {
    tests.authSecret = true;
  } else {
    errors.push("AUTH_SECRET: Not set");
  }

  return new Response(
    JSON.stringify({
      tests,
      errors,
      allPassed: Object.values(tests).every((t) => t),
    }),
    {
      headers: { "Content-Type": "application/json" },
    },
  );
}
