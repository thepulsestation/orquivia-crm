export function ensureFlows(data){
 data.settings.flows??=[{id:'documental',name:'Certificación y documentación',continuous:false,stages:['Nuevo','En revisión','Pendiente de cliente','Aprobado']},{id:'continuo',name:'Local · encargos continuos',continuous:true,stages:['Inicio','En ejecución']}];
 for(const d of data.deals)d.flowId??='documental';
 return data.settings.flows;
}
export function flowFor(data,d){return ensureFlows(data).find(f=>f.id===d.flowId)||data.settings.flows[0];}
export function stagesFor(data,d){return flowFor(data,d).stages;}
export function saveFlow(data,v){const flows=ensureFlows(data),stages=String(v.stages||'').split('\n').map(s=>s.trim()).filter(Boolean);if(!v.name?.trim()||!stages.length||new Set(stages).size!==stages.length)throw Error('Indica un nombre y etapas distintas, una por línea.');let f=flows.find(f=>f.id===v.id);if(f){for(const d of data.deals.filter(d=>d.flowId===f.id)){const previous=f.stages[d.stage];if(!stages.includes(previous))throw Error('La etapa «'+previous+'» contiene proyectos. Muévelos antes de eliminarla o renombrarla.');d.stage=stages.indexOf(previous);}}else{f={id:crypto.randomUUID()};flows.push(f);}Object.assign(f,{name:v.name.trim(),stages,continuous:v.continuous==='on'});return f;}
