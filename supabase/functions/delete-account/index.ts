// Supabase Edge Function: delete-account
//
// Permanently deletes the authenticated user's account and personal data,
// satisfying Google Play's in-app account deletion requirement.
//
// Behaviour (matches https://winkidoo.com/delete-account):
//  - The user's auth account and all directly-owned data are deleted
//    (profile, push tokens, winks balance, notifications, character chat,
//    friends, dares, etc. — via ON DELETE CASCADE from auth.users).
//  - SHARED COUPLE VAULT IS PRESERVED FOR THE PARTNER: if the leaving user is
//    the couple creator (user_a) and a partner (user_b) exists, ownership is
//    transferred to the partner and the leaving user's surprises/quests are
//    reassigned to them so the partner keeps their shared memories.
//  - If the user is the partner (user_b), they are simply detached.
//  - If the user is solo (no partner), the couple row cascades away.
//
// Auth: requires a valid Supabase user JWT in the Authorization header.
//
// Setup:
//   supabase functions deploy delete-account --use-api
//   (uses the auto-injected SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY secrets)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

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

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!jwt) {
    return json({ error: "Missing Authorization bearer token" }, 401);
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Resolve the caller from their JWT — never trust a user id from the body.
  const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return json({ error: "Invalid or expired session" }, 401);
  }
  const uid = userData.user.id;

  try {
    // 1. Find every couple this user belongs to (usually one).
    const { data: couples, error: coupleErr } = await admin
      .from("couples")
      .select("id, user_a_id, user_b_id")
      .or(`user_a_id.eq.${uid},user_b_id.eq.${uid}`);

    if (coupleErr) throw coupleErr;

    for (const couple of couples ?? []) {
      const isCreator = couple.user_a_id === uid;
      const partnerId = isCreator ? couple.user_b_id : couple.user_a_id;

      if (isCreator && partnerId) {
        // Preserve the partner's vault: promote partner to owner, then
        // reassign this user's couple-scoped content to the partner so it
        // is not cascade-deleted when the auth user is removed.
        const { error: promoteErr } = await admin
          .from("couples")
          .update({ user_a_id: partnerId, user_b_id: null })
          .eq("id", couple.id);
        if (promoteErr) throw promoteErr;

        // surprises.creator_id and quests.creator_id reference auth.users with
        // ON DELETE CASCADE / RESTRICT respectively — reassign to the partner.
        await admin
          .from("surprises")
          .update({ creator_id: partnerId })
          .eq("couple_id", couple.id)
          .eq("creator_id", uid);

        await admin
          .from("quests")
          .update({ creator_id: partnerId })
          .eq("couple_id", couple.id)
          .eq("creator_id", uid);
      } else if (!isCreator) {
        // User is the partner (user_b): detach them. The creator keeps the
        // couple. This user's own surprises/quests cascade away with the user.
        // quests.creator_id has no cascade, so clear those rows first.
        await admin
          .from("couples")
          .update({ user_b_id: null })
          .eq("id", couple.id);

        await admin.from("quests").delete().eq("creator_id", uid);
      } else {
        // Solo creator, no partner: the couple row cascades when the user is
        // deleted. quests.creator_id has no cascade — delete them explicitly.
        await admin.from("quests").delete().eq("creator_id", uid);
      }
    }

    // Safety net: remove any remaining quests authored by this user that are
    // not protected by a cascade, so the auth delete can't be blocked.
    await admin.from("quests").delete().eq("creator_id", uid);

    // 2. Best-effort storage cleanup for the user's personal buckets.
    //    Files are keyed by `<uid>/...`. Surprise media is keyed by coupleId
    //    and is intentionally preserved with the couple.
    for (const bucket of ["profile-avatars", "judge-avatars"]) {
      try {
        const { data: files } = await admin.storage.from(bucket).list(uid);
        if (files && files.length > 0) {
          await admin.storage
            .from(bucket)
            .remove(files.map((f) => `${uid}/${f.name}`));
        }
      } catch (_) {
        // Non-fatal: storage cleanup failure should not block account deletion.
      }
    }

    // 3. Delete the auth user. ON DELETE CASCADE removes all remaining
    //    user-keyed rows across the schema.
    const { error: delErr } = await admin.auth.admin.deleteUser(uid);
    if (delErr) throw delErr;

    return json({ success: true });
  } catch (e) {
    console.error("delete-account failed:", e);
    return json({ error: "Account deletion failed. Please contact support." }, 500);
  }
});
