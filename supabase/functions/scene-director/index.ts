// Supabase Edge Function: scene-director
//
// The AI Director + castmates for Scene Party. Runs Gemini SERVER-SIDE
// (gemini-proxy pattern: JWT-authenticated, key never leaves the server) and
// inserts bot rows into character_chat_messages via the service role — the
// tightened insert RLS (migration 058) makes client forgery impossible.
//
// Actions (POST {action, room_id}):
//   start     — creator flips casting→live; Director opens Act 1 (+ castmate intros)
//   tick      — fire-and-forget after every user message; runs AT MOST one unit
//               of due work: act close > director beat > castmate reply
//   end_scene — creator ends early; Director wraps
//
// Concurrency: every client ticks, so turns are claimed via the
// claim_director_turn CAS (+25s lease, migration 060) — N concurrent ticks
// produce exactly ONE director action. A failed Gemini call never blocks chat:
// canned fallbacks for openers/transitions, silent skip for beats.
//
// Deploy: supabase functions deploy scene-director --use-api
// Secrets: GEMINI_API_KEY (already set for gemini-proxy).

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  bestPerformanceJudging,
  castmateReply,
  CastRow,
  directorBeat,
  directorOpener,
  actTransition,
  FALLBACK_TRANSITION,
  FALLBACK_WRAP,
  MessageRow,
  sceneWrap,
} from "./prompts.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

// Turn policy thresholds (mirrored in lib/core/utils/scene_state.dart).
const DIRECTOR_BEAT_EVERY = 6; // user messages between director interjections
const CASTMATE_REPLY_EVERY = 2; // user messages between castmate replies
const CASTMATE_MAX_PER_ACT = 8;

// Rate limits (check_rate_limit RPC, migration 042).
const USER_TICK_MAX = 30, USER_TICK_WINDOW = 300;
const ROOM_BURST_MAX = 40, ROOM_BURST_WINDOW = 600;
const ROOM_DAILY_MAX = 300, ROOM_DAILY_WINDOW = 86400;

const SAFETY_SETTINGS = [
  "HARM_CATEGORY_HARASSMENT",
  "HARM_CATEGORY_HATE_SPEECH",
  "HARM_CATEGORY_SEXUALLY_EXPLICIT",
  "HARM_CATEGORY_DANGEROUS_CONTENT",
].map((category) => ({ category, threshold: "BLOCK_MEDIUM_AND_ABOVE" }));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function gemini(
  prompt: string,
  opts: { maxOutputTokens: number; asJson?: boolean },
): Promise<string | null> {
  try {
    const resp = await fetch(GEMINI_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.9,
          maxOutputTokens: opts.maxOutputTokens,
          thinkingConfig: { thinkingBudget: 0 },
          ...(opts.asJson ? { responseMimeType: "application/json" } : {}),
        },
        safetySettings: SAFETY_SETTINGS,
      }),
    });
    if (!resp.ok) {
      console.error("scene-director: gemini", resp.status, await resp.text());
      return null;
    }
    const data = await resp.json();
    const text: string | undefined = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return text?.trim() || null;
  } catch (e) {
    console.error("scene-director: gemini fetch failed", e);
    return null;
  }
}

function parseJsonLoose(raw: string): Record<string, unknown> | null {
  try {
    return JSON.parse(raw);
  } catch (_) {
    const a = raw.indexOf("{"), b = raw.lastIndexOf("}");
    if (a >= 0 && b > a) {
      try {
        return JSON.parse(raw.slice(a, b + 1));
      } catch (_) { /* fall through */ }
    }
    return null;
  }
}

async function insertBotMessage(
  admin: SupabaseClient,
  roomId: string,
  type: "director" | "castmate" | "system",
  text: string,
  opts: { characterId?: string; characterName?: string; payload?: unknown } = {},
): Promise<void> {
  const { error } = await admin.from("character_chat_messages").insert({
    room_id: roomId,
    sender_id: null,
    original_content: text,
    message_type: type,
    character_id: opts.characterId ?? (type === "director" ? "director" : "system"),
    character_name: opts.characterName ?? (type === "director" ? "Director" : "Scene"),
    payload: opts.payload ?? null,
  });
  if (error) console.error("scene-director: insert message failed", error);
}

async function rateLimited(
  admin: SupabaseClient,
  userId: string,
  action: string,
  max: number,
  windowSeconds: number,
): Promise<boolean> {
  try {
    const { data } = await admin.rpc("check_rate_limit", {
      p_user_id: userId,
      p_action: action,
      p_max_attempts: max,
      p_window_seconds: windowSeconds,
    });
    return data?.allowed === false;
  } catch (e) {
    console.error("scene-director: rate-limit check failed (allowing)", e);
    return false;
  }
}

/** Which unit of work is due this tick? Mirrored in scene_state.dart. */
export function decideTick(session: {
  user_msgs_in_act: number;
  msgs_since_director: number;
  msgs_since_castmate: number;
  castmate_msgs_in_act: number;
}, minUserMessages: number, aiCastCount: number):
  | "act_close"
  | "beat"
  | "castmate"
  | null {
  if (session.user_msgs_in_act >= minUserMessages) return "act_close";
  if (session.msgs_since_director >= DIRECTOR_BEAT_EVERY) return "beat";
  if (
    session.msgs_since_castmate >= CASTMATE_REPLY_EVERY &&
    aiCastCount > 0 &&
    session.castmate_msgs_in_act < CASTMATE_MAX_PER_ACT
  ) return "castmate";
  return null;
}

/** Pick which AI castmate replies: addressed-by-name first, else least recent. */
export function pickCastmate(aiCast: CastRow[], messages: MessageRow[]): CastRow {
  const lastUser = [...messages].reverse().find((m) => m.message_type === "user");
  if (lastUser) {
    const text = (lastUser.transformed_content ?? lastUser.original_content).toLowerCase();
    const addressed = aiCast.find((c) =>
      c.character_name.toLowerCase().split(" ").some((w) => w.length > 3 && text.includes(w))
    );
    if (addressed) return addressed;
  }
  // Least-recently spoken: scan backwards; unspoken castmates rank first.
  const lastIndex = new Map<string, number>();
  messages.forEach((m, i) => {
    if (m.message_type === "castmate") lastIndex.set(m.character_name, i);
  });
  return [...aiCast].sort(
    (a, b) =>
      (lastIndex.get(a.character_name) ?? -1) - (lastIndex.get(b.character_name) ?? -1),
  )[0];
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!GEMINI_API_KEY) return json({ error: "Server misconfiguration" }, 500);

  // 1. Authenticate the caller.
  const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!jwt) return json({ error: "Missing Authorization bearer token" }, 401);
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
  if (userErr || !userData?.user) return json({ error: "Invalid or expired session" }, 401);
  const uid = userData.user.id;

  let body: { action?: string; room_id?: string };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "Invalid JSON body" }, 400);
  }
  const action = body.action ?? "";
  const roomId = body.room_id ?? "";
  if (!["start", "tick", "end_scene"].includes(action) || !roomId) {
    return json({ error: "Bad request" }, 400);
  }

  // 2. Per-user tick backstop.
  if (await rateLimited(admin, uid, "scene_tick", USER_TICK_MAX, USER_TICK_WINDOW)) {
    return json({ skipped: "rate_limited_user" });
  }

  // 3. Caller must be an ACTIVE member; room must have a session.
  const { data: membership } = await admin
    .from("character_chat_members")
    .select("user_id")
    .eq("room_id", roomId).eq("user_id", uid).eq("status", "active")
    .maybeSingle();
  if (!membership) return json({ error: "Not an active member" }, 403);

  const { data: session } = await admin
    .from("scene_sessions").select("*").eq("room_id", roomId).maybeSingle();
  if (!session) return json({ error: "No scene in this room" }, 404);

  // 4. Load pack, acts, cast, recent messages (service role).
  const [{ data: pack }, { data: acts }, { data: castRows }, { data: msgRows }] =
    await Promise.all([
      admin.from("scene_packs").select("*").eq("id", session.pack_id).single(),
      admin.from("scene_act_templates").select("*")
        .eq("pack_id", session.pack_id).order("act_number"),
      admin.from("scene_cast")
        .select("character_id, user_id, is_ai, best_performance_count, scene_characters(slug, name, castmate_prompt)")
        .eq("session_id", session.id),
      admin.from("character_chat_messages")
        .select("message_type, character_name, original_content, transformed_content")
        .eq("room_id", roomId).order("created_at", { ascending: true }).limit(60),
    ]);
  if (!pack || !acts || !castRows) return json({ error: "Scene data missing" }, 500);

  // profiles hangs off auth.users, not scene_cast — fetch names separately.
  const humanIds = castRows
    .map((r: Record<string, any>) => r.user_id)
    .filter((id: string | null): id is string => id != null);
  const nameById = new Map<string, string>();
  if (humanIds.length > 0) {
    const { data: profs } = await admin
      .from("profiles").select("user_id, display_name").in("user_id", humanIds);
    for (const p of profs ?? []) {
      if (p.display_name) nameById.set(p.user_id, p.display_name);
    }
  }

  const cast: CastRow[] = castRows.map((r: Record<string, any>) => ({
    character_slug: r.scene_characters?.slug ?? "",
    character_name: r.scene_characters?.name ?? "Character",
    castmate_prompt: r.scene_characters?.castmate_prompt ?? "",
    is_ai: r.is_ai as boolean,
    display_name: r.user_id ? nameById.get(r.user_id) ?? null : null,
  }));
  const aiCast = cast.filter((c) => c.is_ai);
  const humanCastRows = castRows.filter((r: Record<string, any>) => !r.is_ai);
  const messages: MessageRow[] = (msgRows ?? []) as MessageRow[];
  const actOf = (n: number) => acts.find((a: Record<string, any>) => a.act_number === n);

  // Room-level cost caps, keyed to the session creator so they're room-global.
  const roomCapped = async () =>
    (await rateLimited(admin, session.created_by, `scene_ai:${roomId}`, ROOM_BURST_MAX, ROOM_BURST_WINDOW)) ||
    (await rateLimited(admin, session.created_by, `scene_day:${roomId}`, ROOM_DAILY_MAX, ROOM_DAILY_WINDOW));

  const claimTurn = async (): Promise<boolean> => {
    const { data } = await admin.rpc("claim_director_turn", {
      p_session_id: session.id,
      p_expected_version: session.version,
    });
    return data != null && (Array.isArray(data) ? data.length > 0 : true);
  };

  const releaseTurn = (extra: Record<string, unknown> = {}) =>
    admin.from("scene_sessions")
      .update({ director_busy_until: null, ...extra })
      .eq("id", session.id);

  // ── START ──
  if (action === "start") {
    if (session.status !== "casting") return json({ skipped: "not_casting" });
    if (session.created_by !== uid) return json({ error: "Only the creator starts" }, 403);
    if (humanCastRows.length === 0) return json({ error: "Claim a character first" }, 400);
    if (await roomCapped()) return json({ skipped: "rate_limited_room" });
    if (!(await claimTurn())) return json({ skipped: "turn_taken" });

    const act1 = actOf(1);
    const opener = (await gemini(
      directorOpener({
        settingPrompt: pack.setting_prompt,
        actTitle: act1?.title ?? "Act 1",
        directorBrief: act1?.director_brief ?? "Open the scene.",
        cast,
      }),
      { maxOutputTokens: 300 },
    )) ?? pack.opening_line ??
      `The scene begins... 🎬 ACT 1 — ${act1?.title ?? "Act 1"}`;
    await insertBotMessage(admin, roomId, "director", opener, {
      payload: { type: "act_open", act: 1 },
    });

    // Up to 2 castmate intro lines so a solo player is never alone.
    for (const c of aiCast.slice(0, 2)) {
      const line = await gemini(
        castmateReply({ settingPrompt: pack.setting_prompt, character: c, messages }),
        { maxOutputTokens: 120 },
      );
      if (line) {
        await insertBotMessage(admin, roomId, "castmate", line, {
          characterId: c.character_slug,
          characterName: c.character_name,
        });
      }
    }

    await releaseTurn({
      status: "live",
      current_act: 1,
      act_started_at: new Date().toISOString(),
      user_msgs_in_act: 0,
      castmate_msgs_in_act: 0,
    });
    return json({ ok: true, did: "start" });
  }

  // ── END SCENE ──
  if (action === "end_scene") {
    if (session.status !== "live") return json({ skipped: "not_live" });
    if (session.created_by !== uid) return json({ error: "Only the creator ends" }, 403);
    if (!(await claimTurn())) return json({ skipped: "turn_taken" });

    const wrap = (await gemini(sceneWrap({ cast, messages }), { maxOutputTokens: 300 })) ??
      FALLBACK_WRAP;
    await insertBotMessage(admin, roomId, "director", wrap, {
      payload: { type: "scene_wrap" },
    });
    await releaseTurn({ status: "ended", ended_at: new Date().toISOString() });
    return json({ ok: true, did: "end_scene" });
  }

  // ── TICK ──
  if (session.status !== "live") return json({ skipped: "not_live" });
  const currentAct = actOf(session.current_act);
  const minUserMessages = currentAct?.min_user_messages ?? 12;
  const due = decideTick(session, minUserMessages, aiCast.length);
  if (!due) return json({ skipped: "nothing_due" });
  if (await roomCapped()) return json({ skipped: "rate_limited_room" });
  if (!(await claimTurn())) return json({ skipped: "turn_taken" });

  if (due === "castmate") {
    const c = pickCastmate(aiCast, messages);
    const line = await gemini(
      castmateReply({ settingPrompt: pack.setting_prompt, character: c, messages }),
      { maxOutputTokens: 120 },
    );
    if (line) {
      await insertBotMessage(admin, roomId, "castmate", line, {
        characterId: c.character_slug,
        characterName: c.character_name,
      });
    }
    await releaseTurn();
    return json({ ok: true, did: line ? "castmate" : "castmate_skipped" });
  }

  if (due === "beat") {
    const line = await gemini(
      directorBeat({
        settingPrompt: pack.setting_prompt,
        actNumber: session.current_act,
        actTitle: currentAct?.title ?? `Act ${session.current_act}`,
        directorBrief: currentAct?.director_brief ?? "",
        twistHints: (currentAct?.twist_hints as string[] | null) ?? [],
        userMsgsInAct: session.user_msgs_in_act,
        minUserMessages,
        cast,
        messages,
      }),
      { maxOutputTokens: 300 },
    );
    if (line) {
      await insertBotMessage(admin, roomId, "director", line, {
        payload: { type: "beat", act: session.current_act },
      });
      await releaseTurn();
    } else {
      // Beat failed — don't burn the counter; retry on a later tick.
      await releaseTurn();
    }
    return json({ ok: true, did: line ? "beat" : "beat_skipped" });
  }

  // due === "act_close": Best Performance → transition or wrap.
  let winnerSlug: string | null = null;
  let winnerUserId: string | null = null;
  let superlative = "Best Performance";
  const judged = await gemini(
    bestPerformanceJudging({
      actNumber: session.current_act,
      actTitle: currentAct?.title ?? `Act ${session.current_act}`,
      cast,
      messages,
    }),
    { maxOutputTokens: 400, asJson: true },
  );
  const parsed = judged ? parseJsonLoose(judged) : null;
  if (parsed) {
    const humans = cast.filter((c) => !c.is_ai);
    const match = humans.find((c) => c.character_slug === parsed.winner_character_slug) ??
      humans[0];
    if (match) {
      winnerSlug = match.character_slug;
      superlative = (parsed.superlative as string) || superlative;
      const winnerRow = castRows.find(
        (r: Record<string, any>) => r.scene_characters?.slug === winnerSlug,
      ) as Record<string, any> | undefined;
      winnerUserId = (winnerRow?.user_id as string | null) ?? null;
      if (winnerRow) {
        await admin.from("scene_cast")
          .update({
            best_performance_count:
              ((winnerRow.best_performance_count as number | undefined) ?? 0) + 1,
          })
          .eq("session_id", session.id)
          .eq("character_id", winnerRow.character_id);
      }
      await insertBotMessage(
        admin,
        roomId,
        "director",
        (parsed.commentary as string) ||
          `🏆 ${superlative}: ${match.character_name}!`,
        {
          payload: {
            type: "best_performance",
            act: session.current_act,
            winner_character_slug: winnerSlug,
            winner_user_id: winnerUserId,
            superlative,
          },
        },
      );
    }
  }

  const isLastAct = session.current_act >= (pack.act_count ?? acts.length);
  if (!isLastAct) {
    const nextAct = actOf(session.current_act + 1);
    const transition = (await gemini(
      actTransition({
        settingPrompt: pack.setting_prompt,
        closingActNumber: session.current_act,
        closingActTitle: currentAct?.title ?? "",
        nextActNumber: session.current_act + 1,
        nextActTitle: nextAct?.title ?? `Act ${session.current_act + 1}`,
        nextDirectorBrief: nextAct?.director_brief ?? "Keep the story moving.",
        cast,
        messages,
      }),
      { maxOutputTokens: 300 },
    )) ?? FALLBACK_TRANSITION(session.current_act + 1, nextAct?.title ?? "");
    await insertBotMessage(admin, roomId, "director", transition, {
      payload: { type: "act_open", act: session.current_act + 1 },
    });
    await releaseTurn({
      current_act: session.current_act + 1,
      act_started_at: new Date().toISOString(),
      user_msgs_in_act: 0,
      castmate_msgs_in_act: 0,
    });
  } else {
    const wrap = (await gemini(sceneWrap({ cast, messages }), { maxOutputTokens: 300 })) ??
      FALLBACK_WRAP;
    await insertBotMessage(admin, roomId, "director", wrap, {
      payload: { type: "scene_wrap" },
    });
    await releaseTurn({ status: "ended", ended_at: new Date().toISOString() });
  }

  // In-app act-end notifications (push rides the scene_sessions webhook).
  const winnerName = cast.find((c) => c.character_slug === winnerSlug)?.character_name;
  const notifRows = humanCastRows
    .filter((r: Record<string, any>) => r.user_id !== uid)
    .map((r: Record<string, any>) => ({
      user_id: r.user_id,
      type: "scene_act_ended",
      title: isLastAct ? "🎬 That's a wrap!" : `🎬 Act ${session.current_act} is in the books`,
      body: winnerName != null
        ? `🏆 ${superlative}: ${winnerName}. ${isLastAct ? "See how it ended." : "The next act is starting…"}`
        : (isLastAct ? "The scene just ended — see how it wrapped." : "The next act is starting…"),
      data: { room_id: roomId, session_id: session.id },
    }));
  if (notifRows.length > 0) {
    const { error: notifErr } = await admin.from("notifications").insert(notifRows);
    if (notifErr) console.error("scene-director: notif insert failed", notifErr);
  }

  return json({ ok: true, did: isLastAct ? "scene_end" : "act_close" });
});
