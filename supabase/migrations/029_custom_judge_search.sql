-- 029: Custom judge web search + async generation + notification
-- Adds status tracking and personality-voiced notification text.

ALTER TABLE public.custom_judges ADD COLUMN IF NOT EXISTS status text DEFAULT 'ready';
ALTER TABLE public.custom_judges ADD COLUMN IF NOT EXISTS notification_text text;

-- Set existing rows to 'ready'
UPDATE public.custom_judges SET status = 'ready' WHERE status IS NULL;
