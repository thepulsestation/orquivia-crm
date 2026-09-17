-- Run in SQL Editor. Fixtures and changes are rolled back.
begin;
insert into auth.users(id) values
 ('ca7f0000-0000-4000-8000-000000000001'),
 ('ca7f0000-0000-4000-8000-000000000002');
set local role authenticated;
set local request.jwt.claim.sub = 'ca7f0000-0000-4000-8000-000000000001';
select public.save_crm_workspace('{"schema":2,"test":"A"}',0);
do $$ begin
  if (select count(*) from public.crm_workspaces) <> 1 then raise exception 'OWN_READ_FAILED'; end if;
  begin
    perform public.save_crm_workspace('{"schema":2,"test":"stale"}',0);
    raise exception 'STALE_WRITE_ALLOWED';
  exception when others then
    if sqlerrm <> 'VERSION_CONFLICT' then raise; end if;
  end;
end $$;
set local request.jwt.claim.sub = 'ca7f0000-0000-4000-8000-000000000002';
do $$ begin
  if (select count(*) from public.crm_workspaces) <> 0 then raise exception 'CROSS_USER_READ_ALLOWED'; end if;
  update public.crm_workspaces set payload='{}' where user_id='ca7f0000-0000-4000-8000-000000000001';
  if found then raise exception 'CROSS_USER_UPDATE_ALLOWED'; end if;
end $$;
reset role;
rollback;
select 'PASS: owner read, cross-user isolation, stale-write protection; fixtures rolled back' as result;
