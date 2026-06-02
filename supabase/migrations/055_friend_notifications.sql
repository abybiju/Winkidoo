-- 055_friend_notifications.sql
-- Friend requests and accepts produced NO notification. Add a trigger on
-- user_friends that writes an in-app notification (notifications table is in the
-- realtime publication, so the recipient sees it live):
--   * new pending request  -> notify the RECIPIENT  ("X wants to be friends")
--   * request accepted      -> notify the REQUESTER  ("X accepted your request")
-- Push (when the app is closed) is handled separately by the edge function +
-- a Database Webhook on user_friends; this trigger only covers in-app.

create or replace function public.notify_friend_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient uuid;
  v_actor uuid;
  v_actor_name text;
begin
  if (tg_op = 'INSERT' and new.status = 'pending' and new.requested_by is not null) then
    -- Requester is new.requested_by; recipient is the other party.
    v_actor := new.requested_by;
    v_recipient := case when new.requested_by = new.user_a_id
                        then new.user_b_id else new.user_a_id end;
    select coalesce(nullif(trim(display_name), ''), 'Someone')
      into v_actor_name from public.profiles where user_id = v_actor;

    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_recipient,
      'friend_request',
      'New friend request',
      coalesce(v_actor_name, 'Someone') || ' wants to be friends',
      jsonb_build_object('type', 'friend_request', 'friendship_id', new.id,
                         'from_user_id', v_actor)
    );

  elsif (tg_op = 'UPDATE' and new.status = 'accepted'
         and old.status is distinct from 'accepted' and new.requested_by is not null) then
    -- The accepter is the party who did NOT send the request.
    v_actor := case when new.requested_by = new.user_a_id
                    then new.user_b_id else new.user_a_id end;
    v_recipient := new.requested_by;
    select coalesce(nullif(trim(display_name), ''), 'Someone')
      into v_actor_name from public.profiles where user_id = v_actor;

    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_recipient,
      'friend_accepted',
      'Friend request accepted',
      coalesce(v_actor_name, 'Someone') || ' accepted your friend request',
      jsonb_build_object('type', 'friend_accepted', 'friendship_id', new.id,
                         'from_user_id', v_actor)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_friend_request on public.user_friends;
create trigger trg_notify_friend_request
  after insert on public.user_friends
  for each row execute function public.notify_friend_event();

drop trigger if exists trg_notify_friend_accept on public.user_friends;
create trigger trg_notify_friend_accept
  after update of status on public.user_friends
  for each row execute function public.notify_friend_event();
