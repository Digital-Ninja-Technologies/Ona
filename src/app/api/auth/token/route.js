import { getToken } from "@auth/core/jwt";
import { auth } from "@/auth";
import sql from "@/app/api/utils/sql";
import { hash, verify } from "argon2";

export async function GET(request) {
  const [token, jwt] = await Promise.all([
    getToken({
      req: request,
      secret: process.env.AUTH_SECRET,
      secureCookie: process.env.AUTH_URL.startsWith("https"),
      raw: true,
    }),
    getToken({
      req: request,
      secret: process.env.AUTH_SECRET,
      secureCookie: process.env.AUTH_URL.startsWith("https"),
    }),
  ]);

  if (!jwt) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  return new Response(
    JSON.stringify({
      jwt: token,
      user: {
        id: jwt.sub,
        email: jwt.email,
        name: jwt.name,
      },
    }),
    {
      headers: {
        "Content-Type": "application/json",
      },
    },
  );
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { provider, email, password, name } = body;

    console.log("📥 Signup request received:", {
      provider,
      email,
      hasPassword: !!password,
      name,
    });

    if (!provider || !email || !password) {
      console.error("❌ Missing required fields:", {
        provider: !!provider,
        email: !!email,
        password: !!password,
      });
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const trimmedEmail = email.toLowerCase().trim();

    if (provider === "credentials-signup") {
      try {
        // Check if user already exists in auth_users
        console.log("🔍 Checking if user exists:", trimmedEmail);
        const existingAuthUsers = await sql`
          SELECT * FROM auth_users WHERE email = ${trimmedEmail}
        `;

        if (existingAuthUsers.length > 0) {
          console.log("⚠️ Email already in use:", trimmedEmail);
          return new Response(
            JSON.stringify({ error: "Email already in use" }),
            {
              status: 400,
              headers: { "Content-Type": "application/json" },
            },
          );
        }

        // Create new user in auth_users
        console.log("🔐 Hashing password...");
        const hashedPassword = await hash(password);
        console.log("✅ Password hashed successfully");

        console.log("👤 Creating new auth_user...");
        const newAuthUsers = await sql`
          INSERT INTO auth_users (email, name, "emailVerified", image)
          VALUES (${trimmedEmail}, ${name || null}, NULL, NULL)
          RETURNING id, email, name, image
        `;

        const newAuthUser = newAuthUsers[0];
        console.log("✅ Auth user created:", {
          id: newAuthUser.id,
          email: newAuthUser.email,
        });

        // Create account record
        console.log("🔗 Creating auth_account...");
        await sql`
          INSERT INTO auth_accounts 
          ("userId", provider, type, "providerAccountId", password)
          VALUES (${newAuthUser.id}, 'credentials', 'credentials', ${newAuthUser.id}, ${hashedPassword})
        `;
        console.log("✅ Auth account created");

        // Create corresponding entry in users table for app features
        console.log("👥 Creating users table entry...");
        await sql`
          INSERT INTO users (id, email, name, profile_image, created_at)
          VALUES (${newAuthUser.id}, ${trimmedEmail}, ${name || null}, NULL, NOW())
          ON CONFLICT (id) DO NOTHING
        `;
        console.log("✅ Users table entry created");

        // Create session token
        console.log("🎫 Creating session...");
        const sessionToken = crypto.randomUUID();
        const expires = new Date();
        expires.setDate(expires.getDate() + 30); // 30 days

        await sql`
          INSERT INTO auth_sessions ("userId", "sessionToken", expires)
          VALUES (${newAuthUser.id}, ${sessionToken}, ${expires.toISOString()})
        `;
        console.log("✅ Session created");

        // Generate JWT
        console.log("🔑 Generating JWT...");
        const { encode } = await import("@auth/core/jwt");
        const token = await encode({
          token: {
            sub: newAuthUser.id.toString(),
            email: newAuthUser.email,
            name: newAuthUser.name,
          },
          secret: process.env.AUTH_SECRET,
          maxAge: 30 * 24 * 60 * 60, // 30 days
        });
        console.log("✅ JWT generated successfully");

        console.log("🎉 Signup complete for:", newAuthUser.email);

        return new Response(
          JSON.stringify({
            jwt: token,
            user: {
              id: newAuthUser.id,
              email: newAuthUser.email,
              name: newAuthUser.name,
              image: newAuthUser.image,
            },
          }),
          {
            headers: { "Content-Type": "application/json" },
          },
        );
      } catch (signupError) {
        console.error("💥 Signup error details:", signupError);
        console.error("Stack trace:", signupError.stack);
        return new Response(
          JSON.stringify({
            error: "Failed to create account",
            details: signupError.message,
          }),
          {
            status: 500,
            headers: { "Content-Type": "application/json" },
          },
        );
      }
    } else if (provider === "credentials-signin") {
      // Get user by email
      const users = await sql`
        SELECT * FROM auth_users WHERE email = ${trimmedEmail}
      `;

      if (users.length === 0) {
        return new Response(
          JSON.stringify({ error: "Invalid email or password" }),
          {
            status: 401,
            headers: { "Content-Type": "application/json" },
          },
        );
      }

      const user = users[0];

      // Ensure user exists in users table (sync if missing)
      await sql`
        INSERT INTO users (id, email, name, profile_image, created_at)
        VALUES (${user.id}, ${user.email}, ${user.name}, ${user.image}, NOW())
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email, name = EXCLUDED.name, profile_image = EXCLUDED.profile_image
      `;

      // Get account with password
      const accounts = await sql`
        SELECT * FROM auth_accounts 
        WHERE "userId" = ${user.id} AND provider = 'credentials'
      `;

      if (accounts.length === 0 || !accounts[0].password) {
        return new Response(
          JSON.stringify({ error: "Invalid email or password" }),
          {
            status: 401,
            headers: { "Content-Type": "application/json" },
          },
        );
      }

      // Verify password
      const isValid = await verify(accounts[0].password, password);
      if (!isValid) {
        return new Response(
          JSON.stringify({ error: "Invalid email or password" }),
          {
            status: 401,
            headers: { "Content-Type": "application/json" },
          },
        );
      }

      // Create session token
      const sessionToken = crypto.randomUUID();
      const expires = new Date();
      expires.setDate(expires.getDate() + 30); // 30 days

      await sql`
        INSERT INTO auth_sessions ("userId", "sessionToken", expires)
        VALUES (${user.id}, ${sessionToken}, ${expires.toISOString()})
      `;

      // Generate JWT
      const { encode } = await import("@auth/core/jwt");
      const token = await encode({
        token: {
          sub: user.id.toString(),
          email: user.email,
          name: user.name,
        },
        secret: process.env.AUTH_SECRET,
        maxAge: 30 * 24 * 60 * 60, // 30 days
      });

      return new Response(
        JSON.stringify({
          jwt: token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            image: user.image,
          },
        }),
        {
          headers: { "Content-Type": "application/json" },
        },
      );
    } else {
      return new Response(JSON.stringify({ error: "Invalid provider" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
  } catch (error) {
    console.error("💥 Token POST error:", error);
    console.error("Stack trace:", error.stack);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
}
