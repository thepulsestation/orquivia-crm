import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
test('workspace migration denies anonymous access and checks ownership on writes',async()=>{const sql=await readFile(new URL('../supabase/migrations/202609180001_workspace.sql',import.meta.url),'utf8');assert.match(sql,/enable row level security/i);assert.match(sql,/with check \(\(select auth.uid\(\)\) = user_id\)/);assert.match(sql,/revision=p_revision/);assert.match(sql,/security invoker/);assert.match(sql,/revoke all.*from public,anon/);});
