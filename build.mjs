import {build} from 'esbuild';
import {mkdir,copyFile,readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
await mkdir('dist',{recursive:true});
await build({entryPoints:['workspace.js'],bundle:true,format:'esm',outfile:'dist/app.js',minify:true,sourcemap:false});
for(const file of ['index.html','style.css','workspace.css']) await copyFile(file,'dist/'+file);
let html=await readFile('dist/index.html','utf8');
for(const file of ['app.js','style.css','workspace.css']){
  const hash=createHash('sha256').update(await readFile('dist/'+file)).digest('hex').slice(0,12);
  html=html.replace(new RegExp(file.replaceAll('.','\\.')+'(?:\\?v=[^"\\s]+)?'),file+'?v='+hash);
}
await writeFile('dist/index.html',html);
