import http from 'node:http';
import {readFile} from 'node:fs/promises';
const files={'/':'dist/index.html','/index.html':'dist/index.html','/style.css':'dist/style.css','/workspace.css':'dist/workspace.css','/app.js':'dist/app.js'};
http.createServer(async(req,res)=>{const path=new URL(req.url,'http://localhost').pathname;const file=files[path];if(!file){res.writeHead(404);res.end('Not found');return}try{res.setHeader('Content-Type',file.endsWith('.css')?'text/css':file.endsWith('.js')?'text/javascript':'text/html; charset=utf-8');res.end(await readFile(new URL(file,import.meta.url)))}catch{res.writeHead(500);res.end('Error al cargar la aplicación')}}).listen(4173,'127.0.0.1',()=>console.log('Orquivia: http://127.0.0.1:4173'));
