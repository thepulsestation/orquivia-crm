import {build} from 'esbuild';
import {mkdir,copyFile} from 'node:fs/promises';
await mkdir('dist',{recursive:true});
await build({entryPoints:['workspace.js'],bundle:true,format:'esm',outfile:'dist/app.js',minify:true,sourcemap:false});
for(const file of ['index.html','style.css','workspace.css']) await copyFile(file,'dist/'+file);
