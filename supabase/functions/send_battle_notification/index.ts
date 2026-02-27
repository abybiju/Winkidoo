// Battle-aware push notifications. Triggered by Database Webhook on public.surprises (INSERT/UPDATE).
// Requires: FIREBASE_SERVICE_ACCOUNT (JSON string) in Supabase secrets. No client-triggered sends.
// Idempotency: for UPDATE we only send when a relevant field changed (avoids duplicate sends when unrelated columns update).
// Future: rate-limit reinforcement notifications (e.g. first reinforcement per surprise in 10s window).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

// Duplicate of app battle math for "Resistance Weakened" detection (do not change Dart battle_math).
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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = (await req.json()) as WebhookPayload;
    if (payload.table !== "surprises" || (payload.type !== "INSERT" && payload.type !== "UPDATE")) {
      return new Response(JSON.stringify({ ok: true, skipped: "not surprises insert/update" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const record = payload.record as SurpriseRecord | null;
    const oldRecord = (payload.old_record as SurpriseRecord | null) ?? null;
    if (!record?.id) {
      return new Response(JSON.stringify({ ok: true, skipped: "no record" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // For UPDATE: exit early if no relevant field changed (avoids noise from unrelated column updates).
    const relevantKeys = ["battle_status", "creator_defense_count", "fatigue_level", "difficulty_level", "seeker_score", "resistance_score"];
    function relevantFieldsChanged(newR: Record<string, unknown>, oldR: Record<string, unknown>): boolean {
      for (const key of relevantKeys) {
        if (newR[key] !== oldR[key]) return true;
      }
      return false;
    }
    if (payload.type === "UPDATE" && oldRecord && !relevantFieldsChanged(record as Record<string, unknown>, oldRecord as Record<string, unknown>)) {
      return new Response(JSON.stringify({ ok: true, skipped: "no relevant field change" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const getSeekerId = async (coupleId: string, creatorId: string): Promise<string | null> => {
      const { data: couple, error } = await supabase
        .from("couples")
        .select("user_a_id, user_b_id")
        .eq("id", coupleId)
        .single();
      if (error || !couple) return null;
      const a = couple.user_a_id as string;
      const b = couple.user_b_id as string | null;
      if (creatorId === a) return b;
      if (creatorId === b) return a;
      return b ?? a;
    };

    const getTokens = async (userIds: string[]): Promise<{ token: string; platform: string }[]> => {
      if (userIds.length === 0) return [];
      const { data: rows, error } = await supabase
        .from("user_push_tokens")
        .select("push_token, push_platform")
        .in("user_id", userIds)
        .not("push_token", "is", null);
      if (error || !rows) return [];
      return rows
        .filter((r: { push_token: string | null }) => r.push_token)
        .map((r: { push_token: string; push_platform: string }) => ({ token: r.push_token, platform: r.push_platform }));
    };

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

      if (newStatus === "resolved") {
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

    const userIds = [...new Set(notifications.map((n) => n.userId))];
    const tokens = await getTokens(userIds);
    if (tokens.length === 0 && notifications.length > 0) {
      console.log("No push tokens for recipients", userIds);
    }

    if (FIREBASE_SERVICE_ACCOUNT && tokens.length > 0) {
      let accessToken: string;
      try {
        const sa = JSON.parse(FIREBASE_SERVICE_ACCOUNT) as {
          client_email: string;
          private_key: string;
          project_id: string;
        };
        accessToken = await getGoogleAccessToken(sa.client_email, sa.private_key);
        const projectId = sa.project_id;
        for (const n of notifications) {
          const recipientTokens = await getTokens([n.userId]);
          for (const { token } of recipientTokens) {
            await sendFCM(projectId, accessToken, token, n.title, n.body, n.data);
          }
        }
      } catch (e) {
        console.error("FCM send failed", e);
      }
    }

    return new Response(JSON.stringify({ ok: true, notifications: notifications.length }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

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
