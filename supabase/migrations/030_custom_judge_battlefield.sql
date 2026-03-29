-- 030: Add battlefield toggle for custom judges
ALTER TABLE public.custom_judges ADD COLUMN IF NOT EXISTS is_active_for_battle boolean DEFAULT false;
