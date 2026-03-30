// Push notifications for Winkidoo. Triggered by Database Webhooks on:
//   public.surprises (INSERT/UPDATE) — battle notifications
//   public.judges (INSERT/UPDATE) — seasonal judge arrival
//   public.daily_dares (INSERT/UPDATE) — dare lifecycle
//   public.daily_mini_games (INSERT/UPDATE) — mini-game lifecycle
//   public.couple_campaign_progress (INSERT) — campaign started
//   public.custom_judges (UPDATE) — custom judge ready
//
// Requires: FIREBASE_SERVICE_ACCOUNT (JSON string) in Supabase secrets.
// Idempotency: for UPDATE we only send when a relevant field changed.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

// ── Battle math (duplicated from Dart for resistance-weakened detection) ──
const DIFFICULTY_EASY = 80;
const DIFFICULTY_MEDIUM = 100;
const DIFFICULTY_HARD = 130;
const FATIGUE_DECAY_PER_LEVEL = 2;
const FATIGUE_WEAKENED_MIN_DROP = 3;

const levelToBase: Record<number, number> = {
  1: DIFFICULTY_EASY,
  2: 90,
  3: DIFFICULTY_MEDIUM,
  4: 115,
  5: DIFFICULTY_HARD,
};

function baseResistance(difficultyLevel: number): number {
  const level = Math.min(5, Math.max(1, difficultyLevel));
  return levelToBase[level] ?? DIFFICULTY_MEDIUM;
}

function creatorReinforcement(creatorDefenseCount: number): number {
  if (creatorDefenseCount <= 0) return 0;
  const sum = 50 * (1 - Math.pow(0.8, creatorDefenseCount));
  return Math.round(sum);
}

function effectiveResistance(
  difficultyLevel: number,
  creatorDefenseCount: number,
  fatigueLevel: number
): number {
  const raw =
    baseResistance(difficultyLevel) +
    creatorReinforcement(creatorDefenseCount) -
    fatigueLevel * FATIGUE_DECAY_PER_LEVEL;
  return raw < 0 ? 0 : raw;
}

// ── Types ──
interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
}

interface SurpriseRecord {
  id: string;
  couple_id: string;
  creator_id: string;
  battle_status?: string;
  creator_defense_count?: number;
  fatigue_level?: number;
  difficulty_level?: number;
  resistance_score?: number;
}

interface JudgeRecord {
  id: string;
  name: string;
  season_start: string | null;
  season_end: string | null;
  is_new?: boolean;
  season_push_sent?: boolean;
}

interface DareRecord {
  id: string;
  couple_id: string;
  dare_text: string;
  judge_persona: string;
  status: string;
  user_a_submitted_at: string | null;
  user_b_submitted_at: string | null;
  grade_emoji: string | null;
  grade_score: number | null;
}

interface MiniGameRecord {
  id: string;
  couple_id: string;
  game_type: string;
  game_prompt: string;
  status: string;
  user_a_submitted_at: string | null;
  user_b_submitted_at: string | null;
  grade_emoji: string | null;
}

interface CampaignProgressRecord {
  id: string;
  couple_id: string;
  campaign_id: string;
}

interface CustomJudgeRecord {
  id: string;
  couple_id: string;
  personality_name: string;
  status: string;
  notification_text: string | null;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── Shared helpers ──
function truncate(text: string, maxLen: number): string {
  if (text.length <= maxLen) return text;
  return text.substring(0, maxLen - 1) + "…";
}

const supabaseAdmin = () => createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function getCoupleMembers(coupleId: string): Promise<{ userA: string; userB: string | null }> {
  const { data, error } = await supabaseAdmin()
    .from("couples")
    .select("user_a_id, user_b_id")
    .eq("id", coupleId)
    .single();
  if (error || !data) return { userA: "", userB: null };
  return { userA: data.user_a_id as string, userB: data.user_b_id as string | null };
}

async function getSeekerId(coupleId: string, creatorId: string): Promise<string | null> {
  const { userA, userB } = await getCoupleMembers(coupleId);
  if (creatorId === userA) return userB;
  if (creatorId === userB) return userA;
  return userB ?? userA;
}

async function getTokens(userIds: string[]): Promise<{ token: string; platform: string }[]> {
  if (userIds.length === 0) return [];
  const { data: rows, error } = await supabaseAdmin()
    .from("user_push_tokens")
    .select("push_token, push_platform")
    .in("user_id", userIds)
    .not("push_token", "is", null);
  if (error || !rows) return [];
  return rows
    .filter((r: { push_token: string | null }) => r.push_token)
    .map((r: { push_token: string; push_platform: string }) => ({
      token: r.push_token,
      platform: r.push_platform,
    }));
}

async function sendNotifications(
  notifications: { userId: string; title: string; body: string; data: Record<string, string> }[]
): Promise<number> {
  if (notifications.length === 0 || !FIREBASE_SERVICE_ACCOUNT) {
    if (notifications.length > 0 && !FIREBASE_SERVICE_ACCOUNT) {
      console.log("FIREBASE_SERVICE_ACCOUNT missing, skipping FCM");
    }
    return 0;
  }
  let sent = 0;
  try {
    const sa = JSON.parse(FIREBASE_SERVICE_ACCOUNT) as {
      client_email: string;
      private_key: string;
      project_id: string;
    };
    const accessToken = await getGoogleAccessToken(sa.client_email, sa.private_key);
    const projectId = sa.project_id;
    for (const n of notifications) {
      const recipientTokens = await getTokens([n.userId]);
      for (const { token } of recipientTokens) {
        try {
          await sendFCM(projectId, accessToken, token, n.title, n.body, n.data);
          sent++;
        } catch (e) {
          console.error(`FCM send failed for token ${token.substring(0, 10)}...`, e);
        }
      }
    }
  } catch (e) {
    console.error("FCM auth/send failed", e);
  }
  return sent;
}

// ── Main handler ──
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = (await req.json()) as WebhookPayload;
    const respond = (body: Record<string, unknown>) =>
      new Response(JSON.stringify(body), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // JUDGES — seasonal launch (one-time)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if (payload.table === "judges" && (payload.type === "INSERT" || payload.type === "UPDATE")) {
      const record = payload.record as JudgeRecord | null;
      const oldRecord = (payload.old_record as JudgeRecord | null) ?? null;
      if (!record?.id || !record?.name) return respond({ ok: true, skipped: "judges no record" });

      const isSeasonal = record.season_start != null && record.season_end != null;
      const now = new Date();
      const seasonStartDate = record.season_start ? new Date(record.season_start) : null;
      const seasonActiveNow = seasonStartDate != null && seasonStartDate <= now;
      const oldSeasonStart = oldRecord?.season_start ? new Date(oldRecord.season_start) : null;
      const seasonJustStarted =
        payload.type === "INSERT" || !oldRecord || (oldSeasonStart != null && oldSeasonStart > now);
      const isNew = record.is_new === true;
      const notYetSent = record.season_push_sent !== true;

      if (!isSeasonal || !seasonActiveNow || !seasonJustStarted || !isNew || !notYetSent) {
        return respond({ ok: true, skipped: "judges not season launch" });
      }

      const { data: tokenRows } = await supabaseAdmin()
        .from("user_push_tokens")
        .select("push_token")
        .not("push_token", "is", null);
      const allTokens: string[] = (tokenRows ?? [])
        .filter((r: { push_token: string }) => r.push_token)
        .map((r: { push_token: string }) => r.push_token);

      const title = "✨ A New Judge Has Arrived";
      const body = `Meet ${record.name}. Dare to persuade?`;
      const data: Record<string, string> = { type: "season_launch", judge_id: record.id };

      if (FIREBASE_SERVICE_ACCOUNT && allTokens.length > 0) {
        try {
          const sa = JSON.parse(FIREBASE_SERVICE_ACCOUNT) as {
            client_email: string;
            private_key: string;
            project_id: string;
          };
          const accessToken = await getGoogleAccessToken(sa.client_email, sa.private_key);
          for (const token of allTokens) {
            try {
              await sendFCM(sa.project_id, accessToken, token, title, body, data);
            } catch (e) {
              console.error("FCM season_launch send failed", e);
            }
          }
        } catch (e) {
          console.error("FCM season_launch failed", e);
        }
      }
      await supabaseAdmin().from("judges").update({ season_push_sent: true }).eq("id", record.id);
      return respond({ ok: true, season_launch: true });
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // DAILY DARES
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if (payload.table === "daily_dares" && (payload.type === "INSERT" || payload.type === "UPDATE")) {
      const record = payload.record as DareRecord | null;
      const oldRecord = (payload.old_record as DareRecord | null) ?? null;
      if (!record?.id || !record?.couple_id) return respond({ ok: true, skipped: "dare no record" });

      const { userA, userB } = await getCoupleMembers(record.couple_id);
      const notifications: { userId: string; title: string; body: string; data: Record<string, string> }[] = [];

      if (payload.type === "INSERT") {
        // New dare generated — notify both partners
        const darePreview = truncate(record.dare_text, 60);
        const bothUsers = [userA, userB].filter(Boolean) as string[];
        for (const uid of bothUsers) {
          notifications.push({
            userId: uid,
            title: "💘 Today's Love Dare",
            body: darePreview,
            data: { type: "dare", dare_id: record.id },
          });
        }
      } else if (payload.type === "UPDATE" && oldRecord) {
        const oldStatus = oldRecord.status;
        const newStatus = record.status;

        // Partner submitted — notify the other partner
        if (!oldRecord.user_a_submitted_at && record.user_a_submitted_at && userB) {
          notifications.push({
            userId: userB,
            title: "Your Partner Responded 💬",
            body: "They completed the dare. Your turn!",
            data: { type: "dare", dare_id: record.id },
          });
        }
        if (!oldRecord.user_b_submitted_at && record.user_b_submitted_at && userA) {
          notifications.push({
            userId: userA,
            title: "Your Partner Responded 💬",
            body: "They completed the dare. Your turn!",
            data: { type: "dare", dare_id: record.id },
          });
        }

        // Dare graded — notify both
        if (oldStatus !== "graded" && newStatus === "graded") {
          const emoji = record.grade_emoji ?? "🏆";
          const score = record.grade_score ?? 0;
          const bothUsers = [userA, userB].filter(Boolean) as string[];
          for (const uid of bothUsers) {
            notifications.push({
              userId: uid,
              title: "Dare Results Are In",
              body: `${emoji} Score: ${score}/100`,
              data: { type: "dare_result", dare_id: record.id },
            });
          }
        }
      }

      const sent = await sendNotifications(notifications);
      return respond({ ok: true, table: "daily_dares", sent });
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // DAILY MINI-GAMES
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if (payload.table === "daily_mini_games" && (payload.type === "INSERT" || payload.type === "UPDATE")) {
      const record = payload.record as MiniGameRecord | null;
      const oldRecord = (payload.old_record as MiniGameRecord | null) ?? null;
      if (!record?.id || !record?.couple_id) return respond({ ok: true, skipped: "game no record" });

      const { userA, userB } = await getCoupleMembers(record.couple_id);
      const notifications: { userId: string; title: string; body: string; data: Record<string, string> }[] = [];

      const gameNames: Record<string, string> = {
        would_you_rather: "Would You Rather",
        love_trivia: "Love Trivia",
        caption_this: "Caption This",
        finish_my_sentence: "Finish My Sentence",
      };
      const gameName = gameNames[record.game_type] ?? record.game_type;

      if (payload.type === "INSERT") {
        const promptPreview = truncate(record.game_prompt, 50);
        const bothUsers = [userA, userB].filter(Boolean) as string[];
        for (const uid of bothUsers) {
          notifications.push({
            userId: uid,
            title: "🎮 Game Time!",
            body: `${gameName}: ${promptPreview}`,
            data: { type: "mini_game", game_id: record.id },
          });
        }
      } else if (payload.type === "UPDATE" && oldRecord) {
        // Partner played
        if (!oldRecord.user_a_submitted_at && record.user_a_submitted_at && userB) {
          notifications.push({
            userId: userB,
            title: "Partner Made Their Move 🎯",
            body: `${gameName} — jump in before time runs out!`,
            data: { type: "mini_game", game_id: record.id },
          });
        }
        if (!oldRecord.user_b_submitted_at && record.user_b_submitted_at && userA) {
          notifications.push({
            userId: userA,
            title: "Partner Made Their Move 🎯",
            body: `${gameName} — jump in before time runs out!`,
            data: { type: "mini_game", game_id: record.id },
          });
        }

        // Game graded
        if (oldRecord.status !== "graded" && record.status === "graded") {
          const emoji = record.grade_emoji ?? "🏆";
          const bothUsers = [userA, userB].filter(Boolean) as string[];
          for (const uid of bothUsers) {
            notifications.push({
              userId: uid,
              title: "Game Over! 🎮",
              body: `${emoji} ${gameName} results are ready`,
              data: { type: "mini_game_result", game_id: record.id },
            });
          }
        }
      }

      const sent = await sendNotifications(notifications);
      return respond({ ok: true, table: "daily_mini_games", sent });
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // CAMPAIGN PROGRESS — new campaign started
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if (payload.table === "couple_campaign_progress" && payload.type === "INSERT") {
      const record = payload.record as CampaignProgressRecord | null;
      if (!record?.id || !record?.couple_id) return respond({ ok: true, skipped: "campaign no record" });

      // Fetch campaign title
      const { data: campaign } = await supabaseAdmin()
        .from("campaigns")
        .select("title")
        .eq("id", record.campaign_id)
        .single();
      const title = (campaign?.title as string) ?? "a new campaign";

      const { userA, userB } = await getCoupleMembers(record.couple_id);
      const bothUsers = [userA, userB].filter(Boolean) as string[];
      const notifications = bothUsers.map((uid) => ({
        userId: uid,
        title: "📖 New Adventure Begins",
        body: `Start your journey: ${title}`,
        data: { type: "campaign", campaign_id: record.campaign_id },
      }));

      const sent = await sendNotifications(notifications);
      return respond({ ok: true, table: "couple_campaign_progress", sent });
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // CUSTOM JUDGES — judge ready after generation
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if (payload.table === "custom_judges" && payload.type === "UPDATE") {
      const record = payload.record as CustomJudgeRecord | null;
      const oldRecord = (payload.old_record as CustomJudgeRecord | null) ?? null;
      if (!record?.id || !record?.couple_id) return respond({ ok: true, skipped: "custom_judge no record" });

      // Only notify when status changes to 'ready'
      if (oldRecord?.status === "ready" || record.status !== "ready") {
        return respond({ ok: true, skipped: "custom_judge not newly ready" });
      }

      const notifText = record.notification_text || `${record.personality_name} is ready to judge!`;
      const { userA, userB } = await getCoupleMembers(record.couple_id);
      const bothUsers = [userA, userB].filter(Boolean) as string[];
      const notifications = bothUsers.map((uid) => ({
        userId: uid,
        title: "🎭 Your Custom Judge Is Ready",
        body: truncate(notifText, 80),
        data: { type: "custom_judge_ready", judge_id: record.id },
      }));

      const sent = await sendNotifications(notifications);
      return respond({ ok: true, table: "custom_judges", sent });
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SURPRISES — battle notifications (original)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if (payload.table !== "surprises" || (payload.type !== "INSERT" && payload.type !== "UPDATE")) {
      return respond({ ok: true, skipped: `unhandled table=${payload.table} type=${payload.type}` });
    }

    const record = payload.record as SurpriseRecord | null;
    const oldRecord = (payload.old_record as SurpriseRecord | null) ?? null;
    if (!record?.id) return respond({ ok: true, skipped: "no record" });

    // For UPDATE: exit early if no relevant field changed
    const relevantKeys = [
      "battle_status", "creator_defense_count", "fatigue_level",
      "difficulty_level", "seeker_score", "resistance_score",
    ];
    function relevantFieldsChanged(
      newR: Record<string, unknown>,
      oldR: Record<string, unknown>
    ): boolean {
      for (const key of relevantKeys) {
        if (newR[key] !== oldR[key]) return true;
      }
      return false;
    }
    if (
      payload.type === "UPDATE" &&
      oldRecord &&
      !relevantFieldsChanged(record as Record<string, unknown>, oldRecord as Record<string, unknown>)
    ) {
      return respond({ ok: true, skipped: "no relevant field change" });
    }

    const notifications: { userId: string; title: string; body: string; data: Record<string, string> }[] = [];

    if (payload.type === "INSERT") {
      const seekerId = await getSeekerId(record.couple_id, record.creator_id);
      if (seekerId) {
        notifications.push({
          userId: seekerId,
          title: "A Surprise Awaits",
          body: "Your partner hid something. Can you convince the judge?",
          data: { surprise_id: record.id, battle_status: "active" },
        });
      }
    } else if (payload.type === "UPDATE" && oldRecord) {
      const creatorId = record.creator_id;
      const seekerId = await getSeekerId(record.couple_id, creatorId);
      const oldDefense = (oldRecord.creator_defense_count as number) ?? 0;
      const newDefense = (record.creator_defense_count as number) ?? 0;
      const oldStatus = (oldRecord.battle_status as string) ?? "active";
      const newStatus = (record.battle_status as string) ?? "active";
      const oldFatigue = (oldRecord.fatigue_level as number) ?? 0;
      const newFatigue = (record.fatigue_level as number) ?? 0;
      const diffLevel = (record.difficulty_level as number) ?? 2;
      const defCount = (record.creator_defense_count as number) ?? 0;

      if (newStatus === "resolved" && oldStatus !== "resolved") {
        if (creatorId) {
          notifications.push({
            userId: creatorId,
            title: "The Vault Was Opened",
            body: "The battle is over. See what was inside.",
            data: { surprise_id: record.id, battle_status: "resolved" },
          });
        }
        if (seekerId) {
          notifications.push({
            userId: seekerId,
            title: "The Vault Was Opened",
            body: "The battle is over. See what was inside.",
            data: { surprise_id: record.id, battle_status: "resolved" },
          });
        }
      }

      if (newDefense > oldDefense && seekerId) {
        notifications.push({
          userId: seekerId,
          title: "The Vault Was Reinforced",
          body: "Your partner strengthened the vault. Keep persuading.",
          data: { surprise_id: record.id, battle_status: "active" },
        });
      }

      if (newFatigue > oldFatigue) {
        const oldEff = effectiveResistance(diffLevel, oldDefense, oldFatigue);
        const newEff = effectiveResistance(diffLevel, defCount, newFatigue);
        const drop = oldEff - newEff;
        if (drop >= FATIGUE_WEAKENED_MIN_DROP && creatorId) {
          notifications.push({
            userId: creatorId,
            title: "Resistance Weakened",
            body: "Fatigue has lowered the bar. The seeker is getting closer.",
            data: { surprise_id: record.id, battle_status: "active" },
          });
        }
      }
    }

    const sent = await sendNotifications(notifications);
    return respond({ ok: true, table: "surprises", sent });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// ── FCM / Google OAuth helpers ──

async function getGoogleAccessToken(clientEmail: string, privateKeyPem: string): Promise<string> {
  const pemContents = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };
  const header = { alg: "RS256", typ: "JWT" };
  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));
  const signatureInput = `${headerB64}.${payloadB64}`;
  const signatureInputBytes = new TextEncoder().encode(signatureInput);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    signatureInputBytes
  );
  const jwt = `${signatureInput}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Google OAuth2 failed: ${res.status} ${t}`);
  }
  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

function base64UrlEncode(str: string): string {
  const bytes = new TextEncoder().encode(str);
  return base64UrlEncodeBytes(bytes);
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function sendFCM(
  projectId: string,
  accessToken: string,
  deviceToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      },
    }),
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`FCM send failed: ${res.status} ${t}`);
  }
}
