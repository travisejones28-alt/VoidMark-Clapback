import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fork,spawnSync,execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {once} from 'node:events';

test('authenticated local API, manual handoff, isolation and validation',async()=>{
 const dir=fs.mkdtempSync(path.join(process.cwd(),'.test-server-'));
 const child=fork('companion/server.mjs',['--test-headless'],{env:{...process.env,LOCALAPPDATA:dir},stdio:['ignore','pipe','pipe','ipc']});
 try{
  const [{port,token}]=await once(child,'message');
  const call=async(route,data,headers={})=>{const r=await fetch(`http://127.0.0.1:${port}${route}`,{method:data?'POST':'GET',headers:{'X-Clapback-Token':token,'Content-Type':'application/json',...headers},...(data?{body:JSON.stringify(data)}:{})});return {status:r.status,data:await r.json()};};
  assert.equal((await call('/state',null,{'X-Clapback-Token':'wrong'})).status,403);
  assert.equal((await call('/state',null,{Origin:'https://example.org'})).status,403);
  let s=(await call('/state')).data;assert.equal(s.keySet,false);
  assert.equal((await call('/generate',{key:'nobody',instructions:''})).status,400);
  assert.equal((await call('/settings',{...s.settings,character:'Me-Realm',logPath:path.join(dir,'chat.txt')})).status,200);
  assert.equal((await call('/import',{text:'VMC1\tWrong-Realm\tOther\nin\t123\thi'})).status,400);
  assert.equal((await call('/import',{text:'VMC1\tMe-Realm\tOther\nin\t123\thi'})).status,200);
  s=(await call('/state')).data;assert.equal(s.conversations.length,1);assert.equal(s.selected,'other');assert.equal(s.conversations[0].messages[0].text,'hi');
  assert.equal((await call('/generate',{key:'other',instructions:''})).status,400);
  assert.equal((await call('/settings',{...s.settings,count:99})).status,400);
  assert.equal((await call('/settings',{...s.settings,character:'Alt-Realm'})).status,200);
  assert.equal((await call('/state')).data.conversations.length,0);
  assert.equal((await call('/clear',{})).status,200);
  if(process.platform==='win32'){
    const result=await promisify(execFile)('powershell.exe',['-NoProfile','-STA','-ExecutionPolicy','Bypass','-File','companion/overlay.ps1','-SmokeTest'],{env:{...process.env,CLAPBACK_PORT:String(port),CLAPBACK_TOKEN:token},windowsHide:true,timeout:15000});
    assert.match(result.stdout,/Overlay controls and backend connection passed/);
  }
 }finally{child.kill();await once(child,'exit');fs.rmSync(dir,{recursive:true,force:true});}
});
test('Windows DPAPI roundtrip protects the key without plaintext storage',{skip:process.platform!=='win32'},()=>{
 const run=(mode,value)=>spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File','companion/secrets.ps1','-Mode',mode],{input:value,encoding:'utf8',windowsHide:true});
 const secret='synthetic-test-key';const protectedValue=run('Protect',secret);assert.equal(protectedValue.status,0,protectedValue.stderr);assert.ok(!protectedValue.stdout.includes(secret));
 const plain=run('Unprotect',protectedValue.stdout);assert.equal(plain.status,0,plain.stderr);assert.equal(plain.stdout,secret);
});
