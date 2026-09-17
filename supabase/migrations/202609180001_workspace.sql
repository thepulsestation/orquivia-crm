-- Isolated workspace per authenticated user. Mailbox identities are NOT users.
create table public.crm_workspaces (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);
alter table public.crm_workspaces enable row level security;
revoke all on public.crm_workspaces from anon;
grant select, insert, update on public.crm_workspaces to authenticated;
create policy own_workspace on public.crm_workspaces for all to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Atomic compare-and-swap: a stale browser cannot overwrite newer changes.
create or replace function public.save_crm_workspace(p_payload jsonb,p_revision bigint)
returns bigint language plpgsql security invoker set search_path = public as $$
declare next_revision bigint;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_revision = 0 then
    insert into public.crm_workspaces(user_id,payload) values(auth.uid(),p_payload)
      on conflict do nothing returning revision into next_revision;
  else
    update public.crm_workspaces set payload=p_payload,revision=revision+1,updated_at=now()
      where user_id=auth.uid() and revision=p_revision returning revision into next_revision;
  end if;
  if next_revision is null then raise exception 'VERSION_CONFLICT'; end if;
  return next_revision;
end $$;
revoke all on function public.save_crm_workspace(jsonb,bigint) from public,anon;
grant execute on function public.save_crm_workspace(jsonb,bigint) to authenticated;
