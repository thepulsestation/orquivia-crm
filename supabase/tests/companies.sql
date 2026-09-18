begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('ad000000-0000-4000-8000-000000000001','owner-company-test@example.com',now()),
 ('ad000000-0000-4000-8000-000000000002','member-company-test@example.com',now()),
 ('ad000000-0000-4000-8000-000000000003','outsider-company-test@example.com',now());
set local role authenticated;
do $$
declare c uuid; other_company uuid; token text; n bigint;
begin
 perform set_config('request.jwt.claim.sub','ad000000-0000-4000-8000-000000000001',true);
 c:=public.create_crm_company('Transactional test','{}');
 if public.create_crm_company('Duplicate','{}')<>c then raise exception 'DUPLICATE_BOOTSTRAP';end if;
 token:=public.invite_crm_member(c,'member-company-test@example.com','project');
 perform set_config('request.jwt.claim.sub','ad000000-0000-4000-8000-000000000003',true);
 other_company:=public.create_crm_company('Other company','{}');
 select count(*) into n from public.crm_companies where id=c;if n<>0 then raise exception 'CROSS_COMPANY_READ';end if;
 begin perform public.save_crm_company(c,'{}',1);raise exception 'CROSS_COMPANY_WRITE';exception when others then if sqlerrm<>'COMPANY_ACCESS_DENIED' then raise;end if;end;
 begin perform public.accept_crm_invitation(token);raise exception 'WRONG_EMAIL_ACCEPTED';exception when others then if sqlerrm<>'INVITATION_INVALID_OR_EMAIL_MISMATCH' then raise;end if;end;
 perform set_config('request.jwt.claim.sub','ad000000-0000-4000-8000-000000000002',true);
 if public.accept_crm_invitation(token)<>c then raise exception 'INVITATION_FAILED';end if;
 begin perform public.accept_crm_invitation(token);raise exception 'TOKEN_REUSED';exception when others then if sqlerrm<>'INVITATION_INVALID_OR_EMAIL_MISMATCH' then raise;end if;end;
 select count(*) into n from public.crm_companies;if n<>1 then raise exception 'MEMBERSHIP_READ_FAILED';end if;
 begin perform public.invite_crm_member(c,'unauthorized@example.com','admin');raise exception 'ROLE_ESCALATION';exception when others then if sqlerrm<>'ADMIN_REQUIRED' then raise;end if;end;
 if public.save_crm_company(c,'{}',1)<>2 then raise exception 'SHARED_WRITE_FAILED';end if;
 begin perform public.save_crm_company(c,'{}',1);raise exception 'STALE_WRITE';exception when others then if sqlerrm<>'VERSION_CONFLICT' then raise;end if;end;
 begin perform public.save_crm_company(c,'{"billing":{"requests":[{"assignee":"ad000000-0000-4000-8000-000000000003"}]}}',2);raise exception 'EXTERNAL_ASSIGNEE';exception when others then if sqlerrm<>'INVALID_ASSIGNEE' then raise;end if;end;
end $$;
reset role;
rollback;
select 'PASS: company isolation, invitations, email ownership, role checks, shared writes and revision conflicts. Test fixtures rolled back.' as result;
