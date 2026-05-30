// Supabase Edge Function: tavily-proxy
//
// Server-side proxy for the Tavily web-search API. The Flutter client used to
// call Tavily directly with TAVILY_API_KEY compiled into the APK (for custom-
// judge personality research), exposing the key to anyone who decompiled the
// app. This keeps the key server-side: the client sends the search body here,
// we authenticate the caller, inject the secret key, and forward to Tavily.
//
// Auth: requires a valid Supabase user JWT (same gate as gemini-proxy). A
// per-user rate limit (check_rate_limit RPC, migration 042) is a backstop.
//
// Setup:
//   supabase secrets set TAVILY_API_KEY=<your_key>
//   supabase functions deploy tavily-proxy --use-api
//   (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY are auto-injected)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TAVILY_API_KEY = Deno.env.get("TAVILY_API_KEY") ?? "";

const TAVILY_URL = "https://api.tavily.com/search";

// Custom-judge creation is infrequent; keep the limit tight.
const RATE_LIMIT_MAX = 20;
const RATE_LIMIT_WINDOW_SECONDS = 60;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  if (!TAVILY_API_KEY) {
    console.error("tavily-proxy: TAVILY_API_KEY secret is not set");
    return json({ error: "Server misconfiguration" }, 500);
  }

  // 1. Authenticate the caller from their JWT.
  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!jwt) {
    return json({ error: "Missing Authorization bearer token" }, 401);
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return json({ error: "Invalid or expired session" }, 401);
  }
  const uid = userData.user.id;

  // 2. Per-user rate limit.
  try {
    const { data: rl } = await admin.rpc("check_rate_limit", {
      p_user_id: uid,
      p_action: "tavily",
      p_max_attempts: RATE_LIMIT_MAX,
      p_window_seconds: RATE_LIMIT_WINDOW_SECONDS,
    });
    if (rl && rl.allowed === false) {
      return json(
        { error: "Rate limit exceeded", wait_seconds: rl.wait_seconds },
        429,
      );
    }
  } catch (e) {
    console.error("tavily-proxy: rate-limit check failed (allowing):", e);
  }

  // 3. Build the Tavily request: take the client's search params, inject the
  //    secret api_key server-side, and forward.
  let clientBody: Record<string, unknown>;
  try {
    clientBody = await req.json();
  } catch (_) {
    return json({ error: "Invalid JSON body" }, 400);
  }

  try {
    const tavilyResp = await fetch(TAVILY_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...clientBody, api_key: TAVILY_API_KEY }),
    });

    const respBody = await tavilyResp.text();
    return new Response(respBody, {
      status: tavilyResp.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("tavily-proxy: upstream fetch failed:", e);
    return json({ error: "Upstream request failed" }, 502);
  }
});
