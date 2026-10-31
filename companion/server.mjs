import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
import {config,Conversations,Tailer,parseLine,generate} from './core.mjs';

const here=path.dirname(fileURLToPath(import.meta.url));
const home=path.join(process.env.LOCALAPPDATA||os.homedir(),'VoidMarkClapback');
fs.mkdirSync(home,{recursive:true});
const settingsFile=path.join(home,'config.json'),keyFile=path.join(home,'key.dpapi');
let settings=config(),startup='Ready - use Settings to configure API key and local character.';
try {if(fs.existsSync(settingsFile))settings=config(JSON.parse(fs.readFileSync(settingsFile,'utf8')));}catch {startup='Invalid saved settings; defaults loaded. Save corrected settings.';}
const token=crypto.randomBytes(32).toString('hex');
let store=new Conversations(settings),tail=new Tailer(settings.logPath),apiKey='',status=startup,busy=false,lastRequest=0,lastWhisper=0,epoch=0;
const pending=new Map();
function dpapi(mode,value) {return new Promise((resolve,reject)=>{
  const p=spawn('powershell.exe',['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',path.join(here,'secrets.ps1'),'-Mode',mode],{windowsHide:true,stdio:['pipe','pipe','pipe']});
  let out='';p.stdout.on('data',d=>out+=d);p.stderr.resume();p.on('error',()=>reject(new Error('Windows key storage unavailable.')));p.on('close',code=>code===0?resolve(out.trim()):reject(new Error('Cannot access Windows-protected API key. Save it again.')));p.stdin.on('error',()=>{});p.stdin.end(value);
});}
if(fs.existsSync(keyFile)){try{apiKey=await dpapi('Unprotect',fs.readFileSync(keyFile,'utf8'));}catch(e){status=e.message;}}
async function run(key,instructions='') {
  const c=store.items.get(key);if(!c)throw new Error('Select a conversation first.');
  if(!apiKey)throw new Error('Save your OpenAI API key in Settings first.');
  if(busy)throw new Error('Generation in progress.');
  const remaining=settings.cooldown*1000-(Date.now()-lastRequest);if(remaining>0)throw new Error(`Wait ${Math.ceil(remaining/1000)} seconds before generating.`);
  if(instructions)c.instructions=[...c.instructions,instructions].slice(-5);
  const version=c.version,requestEpoch=epoch,snapshot={...settings};busy=true;lastRequest=Date.now();pending.delete(key);status=`Generating for ${c.player}...`;
  try {
    const replies=await generate(c,snapshot,apiKey);
    if(epoch!==requestEpoch)return;
    if(store.items.get(key)!==c||c.version!==version){status='New conversation activity; outdated suggestions discarded.';return;}
    c.replies=replies;status=`Ready for ${c.player} - review and copy; send manually.`;
  }catch(e){if(epoch===requestEpoch)status=e.message;}finally{busy=false;}
}
async function body(req){let chunks=[],size=0;for await(const chunk of req){size+=chunk.length;if(size>65536)throw new Error('Request too large.');chunks.push(chunk);}return JSON.parse(Buffer.concat(chunks).toString()||'{}');}
const server=http.createServer(async(req,res)=>{
  res.setHeader('Content-Type','application/json');res.setHeader('Cache-Control','no-store');
  const send=(code,data)=>{res.writeHead(code);res.end(JSON.stringify(data));};
  if(req.headers['x-clapback-token']!==token||req.headers.origin)return send(403,{error:'Forbidden'});
  try {
    if(req.method==='GET'&&req.url==='/state'){
      store.prune();return send(200,{settings,keySet:!!apiKey,status,busy,logStatus:tail.status,lastWhisper,selected:store.selected,conversations:[...store.items.entries()].map(([key,c])=>({key,...c}))});
    }
    if(req.method!=='POST')return send(404,{error:'Not found'});
    const data=await body(req);
    switch(req.url){
      case '/select': if(!store.items.has(data.key))throw new Error('Conversation no longer available.');store.selected=data.key;break;
      case '/generate': if(typeof data.instructions!=='string'||data.instructions.length>2000)throw new Error('Instructions must be under 2000 characters.');awaitableRun(data.key,data.instructions);break;
      case '/import': {
        if(typeof data.text!=='string')throw new Error('Paste addon context first.');
        // Check character before accepting any transcript; never mix alt sessions.
        const source=decodeURIComponent(data.text.trim().split(/\r?\n/)[0].split('\t')[1]||'');
        if(!settings.character||source.toLowerCase()!==settings.character.toLowerCase())throw new Error('Set Local character to the exported Name-Realm in Settings first.');
        const {key}=store.import(data.text);pending.delete(key);status='Context imported. Click Generate.';break;
      }
      case '/settings': {
        const next=config(data);const reset=next.character!==settings.character||next.logPath!==settings.logPath;
        fs.writeFileSync(settingsFile,JSON.stringify(next,null,2));settings=next;epoch++;pending.clear();store.settings=settings;
        if(reset){store=new Conversations(settings);tail=new Tailer(settings.logPath);lastWhisper=0;}
        store.prune();status='Settings saved.';break;
      }
      case '/key': {
        if(typeof data.key!=='string'||data.key.length>1000)throw new Error('Invalid API key.');
        const value=data.key.trim();if(value){const encrypted=await dpapi('Protect',value);fs.writeFileSync(keyFile,encrypted);apiKey=value;}else{fs.rmSync(keyFile,{force:true});apiKey='';}epoch++;status=value?'API key saved securely.':'API key removed.';break;
      }
      case '/clear': epoch++;pending.clear();store=new Conversations(settings);status='Memory history cleared. WoW chat log is unchanged.';break;
      default:return send(404,{error:'Not found'});
    }
    send(200,{ok:true});
  }catch(e){send(400,{error:e.message});}
});
function awaitableRun(key,instructions){
  if(!store.items.has(key))throw new Error('Select a conversation.');
  if(busy)throw new Error('Generation in progress.');
  if(!apiKey)throw new Error('Save your API key first.');
  if(Date.now()-lastRequest<settings.cooldown*1000)throw new Error('Generation cooldown active. Try again shortly.');
  void run(key,instructions).catch(e=>status=e.message);
}
const timer=setInterval(()=>{
  store.prune();
  for(const line of tail.poll()){
    const m=parseLine(line);if(!m||!settings.character)continue;
    const key=store.add(m);lastWhisper=Date.now();
    if(m.direction==='in'&&settings.auto&&apiKey)pending.set(key,Date.now());
  }
  if(!busy&&settings.auto&&apiKey&&Date.now()-lastRequest>=settings.cooldown*1000){
    for(const [key,at]of pending){if(!store.items.has(key)){pending.delete(key);continue;}if(Date.now()-at>=1200){void run(key).catch(e=>status=e.message);break;}}
  }
},500);
server.listen(0,'127.0.0.1',()=>{
  if(process.send && process.argv.includes('--test-headless')){process.send({port:server.address().port,token});return;}
  const child=spawn('powershell.exe',['-NoProfile','-STA','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',path.join(here,'overlay.ps1')],{windowsHide:true,env:{...process.env,CLAPBACK_PORT:String(server.address().port),CLAPBACK_TOKEN:token},stdio:['ignore','ignore','pipe']});
  child.stderr.on('data',d=>console.error(String(d)));
  console.log('VoidMark Clapback running. Close its window to exit. No messages are sent to WoW.');
  const shutdown=()=>{clearInterval(timer);server.close();process.exit(0);};child.on('exit',shutdown);child.on('error',()=>{console.error('Cannot start Windows panel. Windows PowerShell is required.');shutdown();});
});
