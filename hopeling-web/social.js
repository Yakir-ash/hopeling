/* Hopeling - social.js: optional account, cloud backup, the pulse.
   Zero dependencies: talks to Supabase's REST APIs directly.
   The app works fully without signing in; this layer only adds. */
var SB_URL='https://cpdjabynilymlfouozcc.supabase.co';
var SB_KEY='sb_publishable_M6ZB-wVDNOvrhzvFE5Fa8A_9jz9L8eL';

function sbSession(){return LS.get('session',null);}
function sbSignedIn(){return !!(sbSession()&&sbSession().access_token);}

function sbRefresh(){
  var s=sbSession();
  if(!s||!s.refresh_token)return Promise.reject(new Error('no session'));
  return fetch(SB_URL+'/auth/v1/token?grant_type=refresh_token',{method:'POST',
    headers:{'apikey':SB_KEY,'Content-Type':'application/json'},
    body:JSON.stringify({refresh_token:s.refresh_token})})
  .then(function(r){if(!r.ok)throw new Error('refresh failed');return r.json();})
  .then(function(d){
    s.access_token=d.access_token;s.refresh_token=d.refresh_token||s.refresh_token;
    s.expires_at=Math.floor(Date.now()/1000)+(d.expires_in||3600);
    LS.set('session',s);return s;
  });
}
function sbAuthed(){
  var s=sbSession();
  if(!s)return Promise.reject(new Error('signed out'));
  if(s.expires_at&&s.expires_at-Math.floor(Date.now()/1000)<90)return sbRefresh();
  return Promise.resolve(s);
}
function sbApi(path,method,body){
  return sbAuthed().then(function(s){
    return fetch(SB_URL+path,{method:method||'GET',
      headers:{'apikey':SB_KEY,'Authorization':'Bearer '+s.access_token,
        'Content-Type':'application/json','Prefer':method==='POST'?'resolution=merge-duplicates,return=minimal':''},
      body:body?JSON.stringify(body):undefined});
  });
}

/* ---- magic link sign-in ---- */
function signIn(){
  var e=document.getElementById('acc_email');
  var email=(e&&e.value||'').trim();
  if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)){toast('Enter a valid email');return;}
  var back=(typeof location!=='undefined')?location.href.split('#')[0]:'https://hopeling.app/hopeling-web/Hopeling.html';
  fetch(SB_URL+'/auth/v1/otp?redirect_to='+encodeURIComponent(back),{method:'POST',
    headers:{'apikey':SB_KEY,'Content-Type':'application/json'},
    body:JSON.stringify({email:email,create_user:true,options:{email_redirect_to:back}})})
  .then(function(r){
    if(r.ok){toast('✉️ Check your email for the magic link');}
    else if(r.status===429){toast('Too many tries - wait a few minutes');}
    else{toast('Could not send the link - try again');}
  }).catch(function(){toast('You seem to be offline');});
}
function handleAuthReturn(){
  if(typeof location==='undefined'||!location.hash||location.hash.indexOf('access_token')<0)return;
  var p={};location.hash.slice(1).split('&').forEach(function(kv){var x=kv.split('=');p[x[0]]=decodeURIComponent(x[1]||'');});
  if(!p.access_token)return;
  var s={access_token:p.access_token,refresh_token:p.refresh_token||'',
    expires_at:Math.floor(Date.now()/1000)+(parseInt(p.expires_in)||3600),email:'',user_id:''};
  LS.set('session',s);
  try{history.replaceState(null,'',location.pathname+location.search);}catch(e){}
  fetch(SB_URL+'/auth/v1/user',{headers:{'apikey':SB_KEY,'Authorization':'Bearer '+s.access_token}})
    .then(function(r){return r.ok?r.json():null;})
    .then(function(u){
      if(u){s.email=u.email||'';s.user_id=u.id||'';LS.set('session',s);}
      toast('🌿 Signed in ✓');cloudBackup(true);render();
    }).catch(function(){});
}
function signOut(){
  var s=sbSession();
  if(s&&s.access_token){fetch(SB_URL+'/auth/v1/logout',{method:'POST',headers:{'apikey':SB_KEY,'Authorization':'Bearer '+s.access_token}}).catch(function(){});}
  LS.set('session',null);toast('Signed out');render();
}

/* ---- cloud backup / restore (explicit restore, auto backup) ---- */
function backupData(){
  var data={_app:'Hopeling',_exported:new Date().toISOString()};
  SAVE_KEYS.forEach(function(k){data[k]=state[k];});
  delete data.theme; /* device preference stays local */
  return data;
}
var _lastCloudSave=0;
function cloudBackup(silent){
  if(!sbSignedIn())return;
  sbApi('/rest/v1/saves','POST',{user_id:sbSession().user_id,data:backupData(),updated_at:new Date().toISOString()})
  .then(function(r){
    if(r.ok||r.status===201){_lastCloudSave=Date.now();LS.set('cloudSaved',new Date().toISOString());if(!silent){toast('☁️ Backed up ✓');render();}}
    else if(!silent)toast('Backup failed - try again');
  }).catch(function(){if(!silent)toast('You seem to be offline');});
}
function cloudAutoSave(){
  if(!sbSignedIn())return;
  if(Date.now()-_lastCloudSave<60000)return; /* at most once a minute */
  cloudBackup(true);
}
function cloudRestore(){
  if(!sbSignedIn())return;
  sbApi('/rest/v1/saves?select=data,updated_at')
  .then(function(r){return r.ok?r.json():null;})
  .then(function(rows){
    if(!rows||!rows.length||!rows[0].data){toast('No cloud backup yet');return;}
    if(!confirm('Restore your cloud backup from '+(rows[0].updated_at||'').slice(0,10)+'? It replaces this device’s progress.'))return;
    var d=rows[0].data;
    SAVE_KEYS.forEach(function(k){if(d[k]!==undefined&&k!=='theme')state[k]=d[k];});
    if(state.customActions){var ca={};Object.keys(state.customActions).forEach(function(k2){if(/^[\w-]+$/.test(k2))ca[k2]=state.customActions[k2];});state.customActions=ca;}
    state.onboarded=true;save();applyTheme();applyKid();render();toast('Progress restored ✓');
  }).catch(function(){toast('Could not reach the cloud');});
}

/* ---- the pulse: every user's actions, counted for real ---- */
function pulseBump(n){
  var q=LS.get('pulseQ',0)+n;LS.set('pulseQ',q);flushPulse();
}
function flushPulse(){
  var q=LS.get('pulseQ',0);
  if(!q||!sbSignedIn())return;
  sbApi('/rest/v1/rpc/log_actions','POST',{n:q})
  .then(function(r){if(r.ok||r.status===204){LS.set('pulseQ',0);getPulse(true);}})
  .catch(function(){});
}
function getPulse(force){
  var c=LS.get('pulse',null);
  if(!force&&c&&Date.now()-c.ts<600000)return;
  fetch(SB_URL+'/rest/v1/pulse?select=actions',{headers:{'apikey':SB_KEY}})
  .then(function(r){return r.ok?r.json():null;})
  .then(function(rows){
    if(rows&&rows.length){LS.set('pulse',{n:rows[0].actions,ts:Date.now()});if(tab==='home')render();}
  }).catch(function(){});
}
function pulseCard(){
  var c=LS.get('pulse',null);
  if(!c||!c.n)return'';
  return '<div class="card" style="text-align:center;padding:10px"><span style="font-weight:700;color:var(--forest)">🌍 '+Number(c.n).toLocaleString()+' actions</span> <span class="muted">taken together by everyone on Hopeling</span></div>';
}

/* ---- account card (Me tab) ---- */
function accountCard(){
  var h='<h2 class="sec">Account</h2><div class="card">';
  if(sbSignedIn()){
    var em=sbSession().email||'signed in';var saved=LS.get('cloudSaved',null);
    h+='<div class="settingrow"><span>☁️ '+esc(em)+'</span><button class="chip" style="margin-left:auto" onclick="signOut()">Sign out</button></div>'+
       '<div class="settingrow"><span>Back up to cloud</span><button class="chip sel" style="margin-left:auto" onclick="cloudBackup()">Back up now</button></div>'+
       '<div class="settingrow"><span>Restore from cloud</span><button class="chip" style="margin-left:auto" onclick="cloudRestore()">Restore</button></div>'+
       (saved?'<div class="muted" style="font-size:12px;padding-top:8px">Last cloud backup: '+esc(saved.slice(0,16).replace('T',' '))+' · backs up automatically as you act</div>':'');
  } else {
    h+='<div style="font-weight:600;margin-bottom:4px">☁️ Keep your grove safe</div>'+
       '<p class="muted" style="margin:0 0 10px">Sign in with your email to back up your progress and restore it on any device. No password - we send you a magic link.</p>'+
       '<div class="field"><input id="acc_email" type="email" inputmode="email" placeholder="you@example.com"/></div>'+
       '<button class="btn" style="margin-top:0" onclick="signIn()">Send magic link</button>';
  }
  return h+'</div>';
}

/* ---- gentle hooks into the core (wrap, never edit) ---- */
if(typeof doAction==='function'){
  var _doAction0=doAction;
  doAction=function(slug){_doAction0(slug);try{pulseBump(1);cloudAutoSave();}catch(e){}};
}
if(typeof finishLesson==='function'){
  var _finishLesson0=finishLesson;
  finishLesson=function(a,b){_finishLesson0(a,b);try{cloudAutoSave();}catch(e){}};
}
try{handleAuthReturn();}catch(e){}
try{if(typeof navigator!=='undefined'&&navigator.onLine!==false){getPulse();flushPulse();}}catch(e){}
