-- Migration 020: Collaborative Vault
-- Run in Supabase Dashboard → SQL Editor

ALTER TABLE surprises
  ADD COLUMN IF NOT EXISTS is_collaborative boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS collab_partner_piece_encrypted text,
  ADD COLUMN IF NOT EXISTS collab_partner_status text NOT NULL DEFAULT 'pending';

-- Index for quickly finding collaborative surprises awaiting partner piece
CREATE INDEX IF NOT EXISTS surprises_collab_idx
  ON surprises (couple_id, is_collaborative, collab_partner_status)
  WHERE is_collaborative = true;
