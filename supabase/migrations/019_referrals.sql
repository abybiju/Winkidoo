-- Migration 019: Couple Referral System
-- Run in Supabase Dashboard → SQL Editor

CREATE TABLE IF NOT EXISTS referrals (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_couple_id  uuid REFERENCES couples(id) ON DELETE SET NULL,
  referrer_invite_code text NOT NULL,
  referred_user_id    uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status              text NOT NULL DEFAULT 'pending',
  reward_claimed      boolean NOT NULL DEFAULT false,
  created_at          timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS referrals_invite_code_idx ON referrals (referrer_invite_code);
CREATE INDEX IF NOT EXISTS referrals_referred_user_idx ON referrals (referred_user_id);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "referrer couple can read own referrals"
  ON referrals FOR SELECT
  USING (
    referrer_couple_id IN (
      SELECT id FROM couples
      WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
    )
  );

CREATE POLICY "anyone can insert referral on signup"
  ON referrals FOR INSERT
  WITH CHECK (true);

CREATE POLICY "referrer couple can update reward_claimed"
  ON referrals FOR UPDATE
  USING (
    referrer_couple_id IN (
      SELECT id FROM couples
      WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
    )
  );
