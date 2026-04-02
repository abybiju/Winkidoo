-- 039: RevenueCat webhook audit log
-- Stores every webhook event from RevenueCat for debugging and reconciliation.

create table if not exists public.revenuecat_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,             -- e.g. INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION
  app_user_id text,                     -- RevenueCat app_user_id (= Supabase auth user ID)
  product_id text,                      -- e.g. winkplus_monthly, winkplus_yearly
  entitlement_id text,                  -- e.g. wink_plus
  expiration_at timestamptz,            -- entitlement expiration from the event
  raw_payload jsonb not null default '{}',
  processed boolean not null default false,
  created_at timestamptz not null default now()
);

-- Index for quick lookup by user
create index if not exists idx_rc_events_user on public.revenuecat_events(app_user_id);

-- RLS: service_role only (Edge Function uses service_role key)
alter table public.revenuecat_events enable row level security;

comment on table public.revenuecat_events is 'Audit log of RevenueCat webhook events for subscription lifecycle tracking.';
