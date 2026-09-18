-- Company tenancy. Existing personal workspaces remain intact as a migration source.
create table public.crm_companies (
 id uuid primary key default gen_random_uuid(), name text not null,
 payload jsonb not null check(jsonb_typeof(payload)='object'), revision bigint not null default 1,
 created_by uuid not null references auth.users(id), updated_at timestamptz not null default now()
);
create table public.crm_members (
 company_id uuid not null references public.crm_companies(id), user_id uuid not null references auth.users(id),
 name text not null, email text not null, role text not null check(role in ('owner','admin','project')),
 primary key(company_id,user_id)
);
create table public.crm_invitations (
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.crm_companies(id),
 email text not null, role text not null check(role in ('admin','project')), token_hash text not null unique,
 expires_at timestamptz not null default now()+interval '7 days', accepted_at timestamptz,
 revoked_at timestamptz, created_by uuid not null references auth.users(id)
);
alter table public.crm_companies enable row level security;
alter table public.crm_members enable row level security;
alter table public.crm_invitations enable row level security;
revoke all on public.crm_companies,public.crm_members,public.crm_invitations from anon,authenticated;
grant select on public.crm_companies,public.crm_members to authenticated;
grant select(id,company_id,email,role,expires_at,accepted_at,revoked_at,created_by) on public.crm_invitations to authenticated;

create function public.crm_company_role(p_company uuid) returns text language sql stable security definer set search_path='' as $$
 select role from public.crm_members where company_id=p_company and user_id=(select auth.uid())
$$;
revoke all on function public.crm_company_role(uuid) from public,anon;
grant execute on function public.crm_company_role(uuid) to authenticated;
create policy company_members_read on public.crm_companies for select to authenticated using(public.crm_company_role(id) is not null);
create policy member_directory_read on public.crm_members for select to authenticated using(public.crm_company_role(company_id) is not null);
create policy invitations_admin_read on public.crm_invitations for select to authenticated using(public.crm_company_role(company_id) in ('owner','admin'));

create function public.create_crm_company(p_name text,p_payload jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare c uuid; u uuid:=auth.uid(); em text; nm text;
begin
 if u is null then raise exception 'AUTH_REQUIRED'; end if;
 -- Serialize bootstrap for a user so concurrent browser tabs cannot create duplicates.
 perform pg_advisory_xact_lock(hashtextextended(u::text,0));
 select company_id into c from public.crm_members where user_id=u limit 1;
 if c is not null then return c; end if;
 select email,coalesce(raw_user_meta_data->>'name',email) into em,nm from auth.users where id=u;
 if nullif(trim(p_name),'') is null then raise exception 'COMPANY_NAME_REQUIRED'; end if;
 insert into public.crm_companies(name,payload,created_by) values(trim(p_name),p_payload,u) returning id into c;
 insert into public.crm_members(company_id,user_id,name,email,role) values(c,u,nm,em,'owner');
 return c;
end $$;

create function public.save_crm_company(p_company uuid,p_payload jsonb,p_revision bigint) returns bigint language plpgsql security definer set search_path='' as $$
declare rev bigint; assignee text;
begin
 if public.crm_company_role(p_company) is null then raise exception 'COMPANY_ACCESS_DENIED'; end if;
 -- Assignees are real members of this company, not arbitrary names or external user ids.
 for assignee in select r->>'assignee' from jsonb_array_elements(coalesce(p_payload#>'{billing,requests}','[]'::jsonb)) r loop
  if assignee is not null and assignee<>'' and not exists(select 1 from public.crm_members where company_id=p_company and user_id::text=assignee) then raise exception 'INVALID_ASSIGNEE'; end if;
 end loop;
 update public.crm_companies set payload=p_payload,revision=revision+1,updated_at=now() where id=p_company and revision=p_revision returning revision into rev;
 if rev is null then raise exception 'VERSION_CONFLICT'; end if;
 return rev;
end $$;

create function public.invite_crm_member(p_company uuid,p_email text,p_role text) returns text language plpgsql security definer set search_path='' as $$
declare token text:=gen_random_uuid()::text||gen_random_uuid()::text;
begin
 if public.crm_company_role(p_company) not in ('owner','admin') or public.crm_company_role(p_company) is null then raise exception 'ADMIN_REQUIRED'; end if;
 if p_role not in ('admin','project') or p_email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then raise exception 'INVALID_INVITATION'; end if;
 if exists(select 1 from public.crm_members where company_id=p_company and lower(email)=lower(trim(p_email))) then raise exception 'ALREADY_MEMBER'; end if;
 insert into public.crm_invitations(company_id,email,role,token_hash,created_by) values(p_company,lower(trim(p_email)),p_role,encode(sha256(convert_to(token,'UTF8')),'hex'),auth.uid());
 return token;
end $$;

create function public.accept_crm_invitation(p_token text) returns uuid language plpgsql security definer set search_path='' as $$
declare inv public.crm_invitations; em text; nm text; verified timestamptz;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
 select email,coalesce(raw_user_meta_data->>'name',email),email_confirmed_at into em,nm,verified from auth.users where id=auth.uid();
 select * into inv from public.crm_invitations where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
 if inv.id is null or inv.revoked_at is not null or inv.accepted_at is not null or inv.expires_at<=now() or lower(em)<>inv.email or verified is null then raise exception 'INVITATION_INVALID_OR_EMAIL_MISMATCH'; end if;
 insert into public.crm_members(company_id,user_id,name,email,role) values(inv.company_id,auth.uid(),nm,em,inv.role) on conflict do nothing;
 update public.crm_invitations set accepted_at=now() where id=inv.id;
 return inv.company_id;
end $$;
create function public.revoke_crm_invitation(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 update public.crm_invitations set revoked_at=now() where id=p_id and accepted_at is null and public.crm_company_role(company_id) in ('owner','admin');
 if not found then raise exception 'INVITATION_NOT_FOUND_OR_DENIED'; end if;
end $$;
create function public.rename_crm_company(p_company uuid,p_name text) returns void language plpgsql security definer set search_path='' as $$
begin
 if nullif(trim(p_name),'') is null then raise exception 'COMPANY_NAME_REQUIRED'; end if;
 update public.crm_companies set name=trim(p_name) where id=p_company and public.crm_company_role(id) in ('owner','admin');
 if not found then raise exception 'ADMIN_REQUIRED'; end if;
end $$;
revoke all on function public.rename_crm_company(uuid,text) from public,anon;
grant execute on function public.rename_crm_company(uuid,text) to authenticated;
revoke all on function public.create_crm_company(text,jsonb),public.save_crm_company(uuid,jsonb,bigint),public.invite_crm_member(uuid,text,text),public.accept_crm_invitation(text),public.revoke_crm_invitation(uuid) from public,anon;
grant execute on function public.create_crm_company(text,jsonb),public.save_crm_company(uuid,jsonb,bigint),public.invite_crm_member(uuid,text,text),public.accept_crm_invitation(text),public.revoke_crm_invitation(uuid) to authenticated;

-- New uploads use company/<company-id>/<file-id>; legacy private files are not exposed.
create policy company_documents_read on storage.objects for select to authenticated using(bucket_id='crm-documents' and (storage.foldername(name))[1]='company' and exists(select 1 from public.crm_members m where m.company_id::text=(storage.foldername(name))[2] and m.user_id=auth.uid()));
create policy company_documents_insert on storage.objects for insert to authenticated with check(bucket_id='crm-documents' and (storage.foldername(name))[1]='company' and exists(select 1 from public.crm_members m where m.company_id::text=(storage.foldername(name))[2] and m.user_id=auth.uid()));
