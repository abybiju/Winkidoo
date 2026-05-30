// Supabase Edge Function: gemini-proxy
//
// Server-side proxy for Google Gemini (Generative Language API). The Flutter
// client used to call Gemini directly with GEMINI_API_KEY compiled into the APK,
// which meant anyone could decompile the app and extract the key. This function
// keeps the key server-side: the app sends the SDK's request here (path + body
// unchanged), we authenticate the caller, attach the secret key, and forward to
// Google — the key never reaches the client.
//
// The client (lib/services/gemini_proxy_client.dart) rewrites the SDK's origin
//   https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent
// to
//   https://<project>.supabase.co/functions/v1/gemini-proxy/v1beta/models/<model>:generateContent
// preserving the subpath, so this proxy is model- and method-agnostic.
//
// Auth: requires a valid Supabase user JWT in the Authorization header. This
// stops the proxy from being an open Gemini relay. A lightweight per-user rate
// limit (via the check_rate_limit RPC, migration 042) is a secondary backstop.
//
// Setup:
//   supabase secrets set GEMINI_API_KEY=<your_key>
//   supabase functions deploy gemini-proxy --use-api
//   (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY are auto-injected)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";

const GOOGLE_BASE = "https://generativelanguage.googleapis.com";
const FUNCTION_PREFIX = "/gemini-proxy";

// Rate limit: generous enough for active battle play (many judge turns), tight
// enough to cap a leaked-token abuser. Per authenticated user.
const RATE_LIMIT_MAX = 60;
const RATE_LIMIT_WINDOW_SECONDS = 60;

// Only allow forwarding to the generateContent surface — not an arbitrary relay.
const ALLOWED_SUBPATH = /^\/v1(beta)?\/models\/[A-Za-z0-9._-]+:(generateContent|streamGenerateContent|countTokens)$/;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-goog-api-key",
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
  if (!GEMINI_API_KEY) {
    console.error("gemini-proxy: GEMINI_API_KEY secret is not set");
    return json({ error: "Server misconfiguration" }, 500);
  }

  // 1. Authenticate the caller from their JWT — never trust the body.
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

  // 2. Per-user rate limit (backstop against a leaked token).
  try {
    const { data: rl } = await admin.rpc("check_rate_limit", {
      p_user_id: uid,
      p_action: "gemini",
      p_max_attempts: RATE_LIMIT_MAX,
      p_window_seconds: RATE_LIMIT_WINDOW_SECONDS,
    });
    if (rl && rl.allowed === false) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded", wait_seconds: rl.wait_seconds }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Retry-After": String(rl.wait_seconds ?? RATE_LIMIT_WINDOW_SECONDS),
          },
        },
      );
    }
  } catch (e) {
    // Rate-limit failure should not take down judging — log and continue.
    console.error("gemini-proxy: rate-limit check failed (allowing):", e);
  }

  // 3. Reconstruct the Google target from the preserved subpath.
  const url = new URL(req.url);
  const idx = url.pathname.indexOf(FUNCTION_PREFIX);
  const subpath = idx >= 0
    ? url.pathname.slice(idx + FUNCTION_PREFIX.length)
    : url.pathname;

  if (!ALLOWED_SUBPATH.test(subpath)) {
    return json({ error: "Unsupported path" }, 400);
  }

  const target = `${GOOGLE_BASE}${subpath}${url.search}`;
  const body = await req.text();

  // 4. Forward to Google with the server-side key. The SDK already produced a
  //    valid Gemini request body, so we pass it through verbatim.
  try {
    const googleResp = await fetch(target, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body,
    });

    const respBody = await googleResp.text();
    return new Response(respBody, {
      status: googleResp.status,
      headers: {
        ...corsHeaders,
        "Content-Type":
          googleResp.headers.get("Content-Type") ?? "application/json",
      },
    });
  } catch (e) {
    console.error("gemini-proxy: upstream fetch failed:", e);
    return json({ error: "Upstream request failed" }, 502);
  }
});
