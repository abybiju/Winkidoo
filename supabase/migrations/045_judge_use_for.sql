-- Migration 045: Add use_for column to custom_judges for battle/chat/both tagging.

ALTER TABLE public.custom_judges
  ADD COLUMN use_for TEXT NOT NULL DEFAULT 'both'
  CHECK (use_for IN ('battle', 'chat', 'both'));

CREATE INDEX idx_custom_judges_use_for ON public.custom_judges(use_for)
  WHERE is_published = true AND is_flagged = false;
