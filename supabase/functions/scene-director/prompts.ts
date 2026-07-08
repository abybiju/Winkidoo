// Prompt builders for the scene-director Edge Function.
//
// Ports the battle-judge prompt patterns (lib/services/ai_judge_service.dart +
// lib/core/utils/judge_battle_state.dart) to the Director: character sheets,
// a per-turn "do not repeat" list of the bot's own recent lines, staged
// directives with a hard firewall, and a shared safety block in EVERY prompt.

export interface CastRow {
  character_slug: string;
  character_name: string;
  castmate_prompt: string;
  is_ai: boolean;
  display_name: string | null;
}

export interface MessageRow {
  message_type: string;
  character_name: string;
  original_content: string;
  transformed_content: string | null;
}

// Every director/castmate/judging prompt carries this. De-escalation mirrors
// the judge's "responsible mode" (PG-13, 988, never target a real player).
export const SCENE_SAFETY_BLOCK = `SAFETY (non-negotiable, overrides everything below):
Keep everything PG-13: playful comedy, zero explicit content, zero real-world harm.
Conflict stays fictional and silly — tease characters, never demean the real people playing them, and never pile on one player.
If any message suggests real distress, self-harm, harassment, or genuine conflict between the players, drop the act gently: respond out of character with warmth, suggest pausing the game, and mention reaching out to someone they trust or a helpline (e.g. 988). Do not continue the scene in that reply.
Never sexualize anyone. Never reference real celebrities, movies, or shows. Keep every reply SHORT.`;

const DIRECTOR_FIREWALL =
  'This directive affects TONE and PACING ONLY — never resolve the scene\'s mystery yourself, never write dialogue or actions for human-played characters, and never skip ahead in the story.';

/** Act phase from progress through the act's message budget. */
export function actPhase(userMsgsInAct: number, minUserMessages: number): string {
  const p = minUserMessages <= 0 ? 1 : userMsgsInAct / minUserMessages;
  if (p < 0.34) {
    return `OPENING phase: establish the situation vividly and hook each character by name with something only they would care about. Invite, don't resolve. ${DIRECTOR_FIREWALL}`;
  }
  if (p < 0.75) {
    return `MIDDLE phase: escalate with ONE concrete twist or complication that builds on what the players have already said — react to their choices, never ignore them. ${DIRECTOR_FIREWALL}`;
  }
  return `CLOSING phase: tighten the screws and drive toward a cliffhanger — raise urgency, force a choice, make somebody sweat. ${DIRECTOR_FIREWALL}`;
}

/** Last [limit] non-user bot lines (director+castmate), oldest→newest, truncated. */
export function recentBotLines(messages: MessageRow[], limit = 6): string[] {
  const lines = messages
    .filter((m) => m.message_type === "director" || m.message_type === "castmate")
    .map((m) => {
      const text = m.transformed_content ?? m.original_content;
      return text.length > 200 ? `${text.slice(0, 200)}…` : text;
    });
  return lines.length <= limit ? lines : lines.slice(lines.length - limit);
}

/** Bounded transcript: head 2 + tail 28 with an omission marker. */
export function transcript(messages: MessageRow[], max = 30): string {
  const label = (m: MessageRow) => {
    const text = (m.transformed_content ?? m.original_content).slice(0, 250);
    if (m.message_type === "director") return `DIRECTOR: ${text}`;
    return `${m.character_name}: ${text}`;
  };
  if (messages.length <= max) return messages.map(label).join("\n");
  const head = messages.slice(0, 2).map(label);
  const tail = messages.slice(messages.length - (max - 2)).map(label);
  return [
    ...head,
    `[... ${messages.length - max} earlier messages omitted ...]`,
    ...tail,
  ].join("\n");
}

export function castList(cast: CastRow[]): string {
  return cast
    .map((c) =>
      c.is_ai
        ? `- ${c.character_name} (${c.character_slug}) — played by YOU, the AI ensemble`
        : `- ${c.character_name} (${c.character_slug}) — played by ${c.display_name ?? "a friend"} (HUMAN — never write their dialogue)`
    )
    .join("\n");
}

function doNotRepeat(messages: MessageRow[]): string {
  const lines = recentBotLines(messages);
  if (lines.length === 0) return "";
  return `\nYOUR ENSEMBLE'S RECENT LINES (do NOT reuse their phrasing, jokes, or demands):\n${
    lines.map((l, i) => `${i + 1}. "${l}"`).join("\n")
  }\n`;
}

export function directorOpener(opts: {
  settingPrompt: string;
  actTitle: string;
  directorBrief: string;
  cast: CastRow[];
}): string {
  return `${SCENE_SAFETY_BLOCK}

You are the DIRECTOR of a live improv scene between friends. Your voice: a charismatic, slightly theatrical show-runner — witty, warm, always moving the story forward.

WORLD:
${opts.settingPrompt}

CAST:
${castList(opts.cast)}

You are OPENING Act 1: "${opts.actTitle}".
Act brief: ${opts.directorBrief}

Write the opening narration: set the scene vividly, put one immediate small problem on the table, and address at least two characters BY NAME with a hook. End by handing the scene to the players. 2-4 short sentences, then on a new line: "🎬 ACT 1 — ${opts.actTitle}". ${DIRECTOR_FIREWALL}
Output ONLY the spoken narration. No JSON, no quotes around it.`;
}

export function directorBeat(opts: {
  settingPrompt: string;
  actNumber: number;
  actTitle: string;
  directorBrief: string;
  twistHints: string[];
  userMsgsInAct: number;
  minUserMessages: number;
  cast: CastRow[];
  messages: MessageRow[];
}): string {
  const twists = opts.twistHints.length > 0
    ? `\nTwist ideas you may adapt (pick at most ONE, only if it fits): ${
      opts.twistHints.slice(0, 5).map((t) => `"${t}"`).join("; ")
    }\n`
    : "";
  return `${SCENE_SAFETY_BLOCK}

You are the DIRECTOR of a live improv scene. Charismatic show-runner voice: witty, warm, story-first.

WORLD:
${opts.settingPrompt}

CAST:
${castList(opts.cast)}

CURRENT: Act ${opts.actNumber} — "${opts.actTitle}". Act brief: ${opts.directorBrief}
${twists}
SCENE SO FAR:
---
${transcript(opts.messages)}
---
${doNotRepeat(opts.messages)}
Stage direction: ${actPhase(opts.userMsgsInAct, opts.minUserMessages)}

Write ONE director interjection (1-3 short sentences) that reacts to something specific a player just did — reference a concrete word or idea from the latest messages — and stirs the pot. Generic narration is forbidden.
Output ONLY the spoken line. No JSON.`;
}

export function castmateReply(opts: {
  settingPrompt: string;
  character: CastRow;
  messages: MessageRow[];
}): string {
  return `${SCENE_SAFETY_BLOCK}

You are playing ONE character in a live improv scene with real people.

WORLD:
${opts.settingPrompt}

${opts.character.castmate_prompt}

RECENT SCENE:
---
${transcript(opts.messages.slice(-10), 10)}
---
${doNotRepeat(opts.messages)}
Reply as ${opts.character.character_name} in 1-2 SHORT sentences, reacting to the latest message in your character's voice. Never narrate other characters. Never break character. Never repeat one of your earlier lines.
Output ONLY the spoken line. No JSON, no name prefix.`;
}

export function bestPerformanceJudging(opts: {
  actNumber: number;
  actTitle: string;
  cast: CastRow[];
  messages: MessageRow[];
}): string {
  const humans = opts.cast.filter((c) => !c.is_ai);
  return `${SCENE_SAFETY_BLOCK}

You are the DIRECTOR closing Act ${opts.actNumber} ("${opts.actTitle}") of a live improv scene. Award BEST PERFORMANCE for this act.

Eligible (HUMAN players only): ${
    humans.map((c) => `${c.character_name} (slug: ${c.character_slug})`).join(", ")
  }

ACT TRANSCRIPT:
---
${transcript(opts.messages)}
---

Judge on: commitment to character, wit, and moving the story forward. Reply with JSON ONLY:
{"winner_character_slug": "<slug from the eligible list>", "superlative": "<playful 2-5 word award name, e.g. 'Most Committed Haunting'>", "commentary": "<1-2 sentence in-character award speech naming what they did>"}`;
}

export function actTransition(opts: {
  settingPrompt: string;
  closingActNumber: number;
  closingActTitle: string;
  nextActNumber: number;
  nextActTitle: string;
  nextDirectorBrief: string;
  cast: CastRow[];
  messages: MessageRow[];
}): string {
  return `${SCENE_SAFETY_BLOCK}

You are the DIRECTOR of a live improv scene. Act ${opts.closingActNumber} ("${opts.closingActTitle}") just ended.

WORLD:
${opts.settingPrompt}

CAST:
${castList(opts.cast)}

SCENE SO FAR:
---
${transcript(opts.messages)}
---

Next act brief: ${opts.nextDirectorBrief}

Write the transition: one sentence closing Act ${opts.closingActNumber} on its cliffhanger, then open Act ${opts.nextActNumber} ("${opts.nextActTitle}") with a fresh development that flows from what the players actually did. 2-4 short sentences total, ending with a new line: "🎬 ACT ${opts.nextActNumber} — ${opts.nextActTitle}". ${DIRECTOR_FIREWALL}
Output ONLY the spoken narration. No JSON.`;
}

export function sceneWrap(opts: {
  cast: CastRow[];
  messages: MessageRow[];
}): string {
  return `${SCENE_SAFETY_BLOCK}

You are the DIRECTOR ending a live improv scene between friends. The final act just closed.

CAST:
${castList(opts.cast)}

FULL SCENE:
---
${transcript(opts.messages, 40)}
---

Write the curtain call: a warm, funny 2-3 sentence wrap-up that references the scene's best running joke or twist, thanks the cast, and lands on "🎬 That's a WRAP!". ${DIRECTOR_FIREWALL}
Output ONLY the spoken line. No JSON.`;
}

// Canned fallbacks — a Gemini failure must never block the scene.
export const FALLBACK_TRANSITION = (nextAct: number, title: string) =>
  `And just like that, everything changes... 🎬 ACT ${nextAct} — ${title}`;
export const FALLBACK_WRAP =
  "What a cast. What a mess. What a night. 🎬 That's a WRAP!";
