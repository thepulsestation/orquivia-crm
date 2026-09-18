import {createClient} from '@supabase/supabase-js';
import {config} from './config.js';
export const configured=Boolean(config.supabaseUrl&&config.supabasePublishableKey);
export const supabase=configured?createClient(config.supabaseUrl,config.supabasePublishableKey):null;
export let activeCompany=null;
export async function companyRpc(name,args){const {data,error}=await supabase.rpc(name,args);if(error)throw error;return data;}
export async function loadRemote(){
 const {data:{user}}=await supabase.auth.getUser();if(!user)throw Error('Inicia sesión de nuevo.');
 const token=sessionStorage.getItem('orquivia-invitation');if(token){const company=await companyRpc('accept_crm_invitation',{p_token:token});localStorage.setItem('orquivia-company',company);sessionStorage.removeItem('orquivia-invitation');}
 let {data:companies,error}=await supabase.from('crm_companies').select('id,name');if(error)throw error;
 if(!companies.length){const {data:legacy,error:legacyError}=await supabase.from('crm_workspaces').select('payload').maybeSingle();if(legacyError)throw legacyError;const {initial}=await import('./model.js');const payload=legacy?.payload||initial(false);const id=await companyRpc('create_crm_company',{p_name:payload.settings.workspace||'Mi empresa',p_payload:payload});companies=[{id,name:payload.settings.workspace||'Mi empresa'}];}
 activeCompany=companies.find(c=>c.id===localStorage.getItem('orquivia-company'))?.id||companies[0].id;
 const {data:row,error:loadError}=await supabase.from('crm_companies').select('payload,revision,name').eq('id',activeCompany).single();if(loadError)throw loadError;
 const {data:members,error:memberError}=await supabase.from('crm_members').select('user_id,name,email,role').eq('company_id',activeCompany);if(memberError)throw memberError;
 const me=members.find(m=>m.user_id===user.id);let invitations=[];if(['owner','admin'].includes(me.role)){const res=await supabase.from('crm_invitations').select('id,email,role,expires_at,accepted_at,revoked_at').eq('company_id',activeCompany);if(res.error)throw res.error;invitations=res.data;}
 row.payload.team={id:activeCompany,name:row.name,currentUser:user.id,members:members.map(m=>({...m,id:m.user_id})),invitations,companies,remote:true};row.payload.settings.name=me.name;row.payload.settings.workspace=row.name;return row;
}
export async function saveRemote(payload,revision){const clean=structuredClone(payload);delete clean.team;return companyRpc('save_crm_company',{p_company:activeCompany,p_payload:clean,p_revision:revision});}
export async function putRemoteFile(file){if(file.size>10*1024*1024)throw Error('El límite por archivo es 10 MB.');let {data:{user}}=await supabase.auth.getUser();if(!user||!activeCompany)throw Error('Inicia sesión de nuevo.');let id=crypto.randomUUID(),path='company/'+activeCompany+'/'+id;let {error}=await supabase.storage.from('crm-documents').upload(path,file,{contentType:'application/octet-stream',upsert:false});if(error)throw error;return {id,path,name:file.name,size:file.size,type:file.type,remote:true};}
export async function getRemoteFile(file){const {data,error}=await supabase.storage.from('crm-documents').download(file.path);if(error)throw error;return new File([data],file.name,{type:'application/octet-stream'});}
const openFiles=()=>new Promise((resolve,reject)=>{const request=indexedDB.open('orquivia-files-v2',1);request.onupgradeneeded=()=>request.result.createObjectStore('files');request.onsuccess=()=>resolve(request.result);request.onerror=()=>reject(request.error)});
export async function putFile(file){if(file.size>10*1024*1024)throw Error('El límite por archivo es 10 MB.');let db=await openFiles(),id=crypto.randomUUID();await new Promise((resolve,reject)=>{let tx=db.transaction('files','readwrite');tx.objectStore('files').put(file,id);tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error)});db.close();return {id,name:file.name,size:file.size,type:file.type};}
export async function getFile(id){let db=await openFiles();let value=await new Promise((resolve,reject)=>{let r=db.transaction('files').objectStore('files').get(id);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});db.close();return value;}
