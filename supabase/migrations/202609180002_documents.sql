insert into storage.buckets(id,name,public,file_size_limit)
values ('crm-documents','crm-documents',false,10485760)
on conflict (id) do nothing;
create policy crm_files_select on storage.objects for select to authenticated
using (bucket_id='crm-documents' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy crm_files_insert on storage.objects for insert to authenticated
with check (bucket_id='crm-documents' and (storage.foldername(name))[1]=(select auth.uid())::text);
