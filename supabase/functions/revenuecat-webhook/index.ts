// Supabase Edge Function: revenuecat-webhook
//
// Receives RevenueCat server-to-server webhook events and updates
// couples.wink_plus_until accordingly.
//
// Setup:
// 1. Deploy: supabase functions deploy revenuecat-webhook --use-api
// 2. Set secret: supabase secrets set REVENUECAT_WEBHOOK_SECRET=<your_secret>
// 3. In RevenueCat dashboard → Integrations → Webhooks:
//    URL: https://<project>.supabase.co/functions/v1/revenuecat-webhook
//    Authorization header: Bearer <REVENUECAT_WEBHOOK_SECRET>
//
// RevenueCat event types we handle:
// - INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE → set wink_plus_until
// - CANCELLATION → keep current expiration (user keeps access until period ends)
// - EXPIRATION, BILLING_ISSUE_DETECTED → clear wink_plus_until

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";

Deno.serve(async (req: Request) => {
  // Only POST
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Verify authorization header
  if (WEBHOOK_SECRET) {
    const auth = req.headers.get("authorization") ?? "";
    if (auth !== `Bearer ${WEBHOOK_SECRET}`) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const event = body?.event;
  if (!event) {
    return new Response("No event in payload", { status: 400 });
  }

  const eventType: string = event.type ?? "UNKNOWN";
  const appUserId: string | null = event.app_user_id ?? null;
  const productId: string | null = event.product_id ?? null;
  const entitlementId: string | null =
    event.entitlement_ids?.[0] ?? null;
  const expirationAtMs: number | null =
    event.expiration_at_ms ?? null;
  const expirationAt: string | null = expirationAtMs
    ? new Date(expirationAtMs).toISOString()
    : null;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // 1. Log the event
  await supabase.from("revenuecat_events").insert({
    event_type: eventType,
    app_user_id: appUserId,
    product_id: productId,
    entitlement_id: entitlementId,
    expiration_at: expirationAt,
    raw_payload: body,
    processed: false,
  });

  // 2. Update couples.wink_plus_until
  if (appUserId) {
    let newWinkPlusUntil: string | null = null;

    switch (eventType) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "PRODUCT_CHANGE":
      case "UNCANCELLATION":
        // Grant/extend access
        newWinkPlusUntil = expirationAt;
        break;

      case "CANCELLATION":
        // User cancelled but still has access until expiration — keep current value.
        // Mark event as processed but don't change wink_plus_until.
        await supabase
          .from("revenuecat_events")
          .update({ processed: true })
          .eq("app_user_id", appUserId)
          .eq("event_type", eventType)
          .order("created_at", { ascending: false })
          .limit(1);
        return new Response(JSON.stringify({ ok: true, action: "cancellation_noted" }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });

      case "EXPIRATION":
      case "BILLING_ISSUE_DETECTED":
        // Revoke access
        newWinkPlusUntil = null;
        break;

      default:
        // Unknown event — log only, no DB change.
        return new Response(JSON.stringify({ ok: true, action: "logged_only" }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
    }

    // Find the couple for this user and update.
    const { data: couples } = await supabase
      .from("couples")
      .select("id")
      .or(`user_a_id.eq.${appUserId},user_b_id.eq.${appUserId}`)
      .limit(1);

    if (couples && couples.length > 0) {
      const coupleId = couples[0].id;
      await supabase
        .from("couples")
        .update({ wink_plus_until: newWinkPlusUntil })
        .eq("id", coupleId);
    }

    // Mark event processed
    await supabase
      .from("revenuecat_events")
      .update({ processed: true })
      .eq("app_user_id", appUserId)
      .eq("event_type", eventType)
      .order("created_at", { ascending: false })
      .limit(1);
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
