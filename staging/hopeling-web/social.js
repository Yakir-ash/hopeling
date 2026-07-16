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
    if(r.ok){LS.set('otpEmail',email);toast('✉️ Check your email for the code');render();}
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
    if(rows&&rows.length){
      var prev=LS.get('pulse',null);
      LS.set('pulse',{n:rows[0].actions,ts:Date.now()});
      var delta=prev&&prev.n?rows[0].actions-prev.n:0;
      if(delta>0)rainDrop(Math.min(delta,40),30);
      if(tab==='home')render();
    }
  }).catch(function(){});
}
var _rainHost=null;
function rainDrop(n,spread){
  try{
    if(typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    n=Math.max(1,Math.min(n||1,40));
    if(!_rainHost){_rainHost=document.createElement('div');_rainHost.className='rainhost';_rainHost.setAttribute('aria-hidden','true');document.body.appendChild(_rainHost);}
    for(var i=0;i<n;i++){
      var d=document.createElement('i');
      d.style.left=(Math.random()*100)+'vw';
      d.style.animationDuration=(1.4+Math.random()*1.4)+'s';
      d.style.animationDelay=(spread?Math.random()*spread:Math.random()*0.35)+'s';
      d.style.opacity=String(0.35+Math.random()*0.5);
      _rainHost.appendChild(d);
    }
    setTimeout(function(){if(_rainHost){var h=_rainHost;_rainHost=null;if(h.parentNode)h.parentNode.removeChild(h);}},((spread||1)+4)*1000);
  }catch(e){}
}
function namedDrop(nm){
  try{
    if(LS.get('quiet',false))return;
    if(typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    var d=document.createElement('span');d.className='ndrop';d.setAttribute('aria-hidden','true');
    d.innerHTML='💧<i>'+esc((nm||'')[0]||'')+'</i>';
    d.style.left=(8+Math.random()*84)+'vw';
    document.body.appendChild(d);
    setTimeout(function(){if(d.parentNode)d.parentNode.removeChild(d);},3200);
  }catch(e){}
}
var _presT=0;
function pollPresence(){
  try{
    if(LS.get('quiet',false))return;
    if(!sbSignedIn())return;
    if(typeof document!=='undefined'&&document.hidden)return;
    if(Date.now()-_presT<55000)return;_presT=Date.now();
    var cs=myCircles();if(!cs.length)return;
    sbApi('/rest/v1/members?circle_id=in.('+cs.map(function(c){return c.id;}).join(',')+')&select=circle_id,user_id,name,week,week_actions')
    .then(function(r){return r.ok?r.json():null;})
    .then(function(rows){
      if(!rows)return;
      var me=(sbSession()||{}).user_id,prev=LS.get('presCache',{}),next={};
      rows.forEach(function(m){
        var k=m.circle_id+'_'+m.user_id;next[k]=m.week_actions||0;
        if(m.user_id!==me&&prev[k]!==undefined&&(m.week_actions||0)>prev[k])namedDrop(m.name);
      });
      LS.set('presCache',next);
    }).catch(function(){});
  }catch(e){}
}
try{if(typeof setInterval!=='undefined')setInterval(pollPresence,60000);}catch(e){}
function cheer(cid,toUser){
  sbApi('/rest/v1/cheers','POST',{circle_id:cid,from_user:(sbSession()||{}).user_id,to_user:toUser,week:weekKey(),emoji:'💚'})
  .then(function(r){
    if(r.ok||r.status===201||r.status===409){hpt(10);toast('💚 Cheered');var c=myCircles().filter(function(x){return x.id===cid;})[0];if(c)openCircleBoard(c.id,c.name,c.code);}
    else toast('Could not cheer');
  }).catch(function(){toast('You seem to be offline');});
}
function pulseCard(){
  var c=LS.get('pulse',null);
  if(!c||!c.n)return'';
  return '<div class="card" style="text-align:center;padding:10px"><span style="font-weight:700;color:var(--forest)">🌍 '+Number(c.n).toLocaleString()+' actions</span> <span class="muted">taken together by everyone on Hopeling</span></div>';
}

/* ---- account card (Me tab) ---- */

function openWhileYouWereHere(){
  var days=Object.keys(state.log||{}).sort();
  var ev=[];
  if(days.length)ev.push([days[0],'\uD83C\uDF31 You planted your seed']);
  (state.rings||[]).forEach(function(r){ev.push([r.end,'\uD83D\uDD25 A '+r.n+'-day streak became a ring']);});
  if(state.guardian&&state.guardian.date)ev.push([state.guardian.date,'\uD83D\uDEE1\uFE0F You took the pledge']);
  var cc=LS.get('contentCache',null)||{};
  var wins=(cc.wins||[]).concat(((cc.news||NEWS)||[]).map(function(n){return {d:n.d,t:n.t,src:n.src};}));
  var seen={};wins=wins.filter(function(w){if(!w.d||!w.t||seen[w.t])return false;seen[w.t]=1;return true;});
  wins.forEach(function(w){ev.push([w.d,'\uD83C\uDF0D '+w.t+(w.src?' \u00b7 '+w.src:'')]);});
  ev.sort(function(a,b){return a[0]<b[0]?1:-1;});
  var head=days.length?('You have been here '+(daysBetween(days[0],today())+1)+' days. '+totalActionsCount()+' actions by you. '+wins.length+' wins for the wild. Same season. Same pull.'):'Your story starts with your first action.';
  openSheet('<div class="card" style="text-align:center"><div style="font-size:40px" aria-hidden="true">\uD83D\uDD52</div><h2 style="margin:6px 0 2px">While you were here</h2><p class="muted">'+head+'</p></div><div class="card">'+ev.slice(0,80).map(function(e){return '<div class="settingrow"><span class="muted" style="font-size:11px;min-width:78px;flex:none">'+esc(e[0])+'</span><span style="font-size:13px">'+esc(e[1])+'</span></div>';}).join('')+'</div>');
}
function verifyCode(){
  var em=LS.get('otpEmail','');var el=document.getElementById('acc_code');
  var code=((el&&el.value)||'').trim();
  if(!/^[0-9]{6,10}$/.test(code)){toast('Enter the code from your email');return;}
  fetch(SB_URL+'/auth/v1/verify',{method:'POST',headers:{'apikey':SB_KEY,'Content-Type':'application/json'},body:JSON.stringify({type:'email',email:em,token:code})})
  .then(function(r){return r.json().then(function(j){return {ok:r.ok,j:j};});})
  .then(function(x){
    if(!x.ok||!x.j.access_token){toast('Wrong or expired code');return;}
    var s={access_token:x.j.access_token,refresh_token:x.j.refresh_token||'',expires_at:Math.floor(Date.now()/1000)+(x.j.expires_in||3600),email:em,user_id:(x.j.user&&x.j.user.id)||''};
    LS.set('session',s);LS.set('otpEmail',null);
    toast('\uD83C\uDF3F Signed in \u2713');cloudBackup(true);render();
  }).catch(function(){toast('You seem to be offline');});
}
function openFeedback(){
  openSheet('<div class="card"><h2 style="margin:0 0 6px">💬 Tell us anything</h2>'+
    '<p class="muted" style="margin-top:0">Bugs, ideas, feelings - it all lands directly with the maker. Every word gets read.</p>'+
    '<div class="field"><textarea id="fb_msg" rows="5" maxlength="2000" placeholder="What\'s on your mind?" style="width:100%;padding:11px;border:0.5px solid var(--line);border-radius:12px;background:var(--card);color:var(--tx);font-size:16px;font-family:inherit"></textarea></div>'+
    '<div class="field"><label for="fb_em">Email (optional, if you\'d like a reply)</label><input id="fb_em" type="email" value="'+esc((sbSession()&&sbSession().email)||'')+'"/></div>'+
    '<button class="btn" onclick="sendFeedback()">Send 💚</button></div>');
}
function sendFeedback(){
  var m=((document.getElementById('fb_msg')||{}).value||'').trim();
  var em=((document.getElementById('fb_em')||{}).value||'').trim();
  if(m.length<3){toast('Write a little something first');return;}
  var s=sbSession();
  var hdrs={'apikey':SB_KEY,'Content-Type':'application/json','Prefer':'return=minimal'};
  if(s&&s.access_token)hdrs['Authorization']='Bearer '+s.access_token;
  fetch(SB_URL+'/rest/v1/feedback',{method:'POST',headers:hdrs,body:JSON.stringify({
    message:m.slice(0,2000),email:em?em.slice(0,120):null,
    user_id:(s&&s.user_id)||null,meta:APP_V+' · '+(navigator.userAgent||'').slice(0,200)
  })}).then(function(r){
    if(r.ok){closeSheet();toast('💚 Thank you - we read every word');}
    else toast('Could not send - try again');
  }).catch(function(){toast('You seem to be offline');});
}
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
       '<button class="btn" style="margin-top:0" onclick="signIn()">Email me a sign-in code</button>'+(LS.get('otpEmail','')?'<div class="field" style="margin-top:12px"><label for="acc_code">6-digit code from your email</label><input id="acc_code" inputmode="numeric" maxlength="10" placeholder="123456"/></div><button class="btn" style="margin-top:0" onclick="verifyCode()">Verify code</button>':'');
  }
  return h+'</div>';
}


/* ---- circles: private teams, joined by code, pulling together ---- */
function wkOf(ds){var d=new Date(ds);var oj=new Date(d.getFullYear(),0,1);var w=Math.ceil((((d-oj)/86400000)+oj.getDay()+1)/7);return d.getFullYear()+'-W'+w;}
function weekActionsCount(){var wk=weekKey(),n=0;Object.keys(state.log||{}).forEach(function(ds){if(wkOf(ds)===wk)n+=state.log[ds];});return n;}
function totalActionsCount(){var n=0;Object.keys(state.log||{}).forEach(function(ds){n+=state.log[ds];});return n;}
function displayName(){return LS.get('displayName','')||'';}

var _lastCircleSync=0;
function syncCircles(force){
  if(!sbSignedIn())return;
  if(!force&&Date.now()-_lastCircleSync<120000)return;
  _lastCircleSync=Date.now();
  sbApi('/rest/v1/members?user_id=eq.'+sbSession().user_id,'PATCH',{
    week:weekKey(),week_actions:Math.min(1000,weekActionsCount()),
    streak:Math.min(20000,state.streak),total_actions:Math.min(1000000,totalActionsCount()),
    stage:(typeof groveStageIdx==='function')?groveStageIdx(state.streak):0,
    last_action:today()
  }).catch(function(){});
  myCircles().forEach(function(c){sbApi('/rest/v1/rpc/feed_flame','POST',{cid:c.id}).catch(function(){});});
}
function myCircles(){return LS.get('myCircles',[]);}
function fetchMyCircles(){
  if(!sbSignedIn())return Promise.resolve([]);
  return sbApi('/rest/v1/members?select=circle_id,circles(id,name,code)&user_id=eq.'+sbSession().user_id)
  .then(function(r){return r.ok?r.json():[];})
  .then(function(rows){
    var cs=(rows||[]).filter(function(x){return x.circles;}).map(function(x){return {id:x.circles.id,name:x.circles.name,code:x.circles.code};});
    LS.set('myCircles',cs);return cs;
  });
}
function createCircle(){
  var cn=(document.getElementById('cc_name')||{}).value||'';
  var dn=(document.getElementById('cc_me')||{}).value||'';
  if(!cn.trim()){toast('Name your circle');return;}
  if(!dn.trim()){toast('Add your display name');return;}
  LS.set('displayName',dn.trim());
  sbApi('/rest/v1/rpc/create_circle','POST',{cname:cn.trim(),dname:dn.trim()})
  .then(function(r){return r.json().then(function(j){return {ok:r.ok,j:j};});})
  .then(function(x){
    if(x.ok){toast('🎉 Circle created');fetchMyCircles().then(function(){syncCircles(true);openCircleBoard(x.j.id,x.j.name,x.j.code);});}
    else toast((x.j&&x.j.message)?x.j.message.replace(/^.*: /,''):'Could not create circle');
  }).catch(function(){toast('You seem to be offline');});
}
function joinCircle(){
  var code=((document.getElementById('jc_code')||{}).value||'').trim().toUpperCase();
  var dn=(document.getElementById('jc_me')||{}).value||'';
  if(!/^[A-Z]{6}$/.test(code)){toast('Codes are 6 letters');return;}
  if(!dn.trim()){toast('Add your display name');return;}
  LS.set('displayName',dn.trim());LS.set('pendingJoin',null);
  sbApi('/rest/v1/rpc/join_circle','POST',{ccode:code,dname:dn.trim()})
  .then(function(r){return r.json().then(function(j){return {ok:r.ok,j:j};});})
  .then(function(x){
    if(x.ok){toast('🌿 Welcome to the circle');fetchMyCircles().then(function(){syncCircles(true);openCircleBoard(x.j.id,x.j.name,x.j.code);});}
    else toast((x.j&&x.j.message)?x.j.message.replace(/^.*: /,''):'Could not join');
  }).catch(function(){toast('You seem to be offline');});
}
function leaveCircle(id,name){
  if(!confirm('Leave "'+name+'"? Your grove and progress stay yours - you just step out of the circle.'))return;
  sbApi('/rest/v1/members?circle_id=eq.'+id+'&user_id=eq.'+sbSession().user_id,'DELETE')
  .then(function(){LS.set('circleHome',null);fetchMyCircles().then(function(){openCircles();});toast('Left the circle');})
  .catch(function(){toast('Could not reach the cloud');});
}
function shareCircleInvite(code,name){
  var url='https://hopeling.app/hopeling-web/Hopeling.html?join='+code;
  var txt='Join my Hopeling circle "'+name+'"! 🌿 Open '+url+' , sign in, and you are in. Code: '+code;
  if(navigator.share){navigator.share({title:'Join my Hopeling circle',text:txt}).catch(function(){});}
  else if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(txt);toast('Invite copied 📋');}
  else toast('Code: '+code);
}
function renderBoard(name,code,rows,extra){
  extra=extra||{};var ch=extra.cheers||{},me=extra.me,cid=extra.cid;
  var wk=weekKey();
  var total=0;(rows||[]).forEach(function(m){if(m.week===wk)total+=(m.week_actions||0);});
  var flameLine='';
  if(extra.flame&&extra.flame.last){
    var alive=(extra.flame.last===today())||(daysBetween(extra.flame.last,today())===1);
    var fd=alive&&extra.flame.start?daysBetween(extra.flame.start,extra.flame.last)+1:0;
    flameLine='<div class="card" style="text-align:center;padding:12px"><span style="font-weight:700;color:var(--forest)">🔥 Circle flame: '+fd+' day'+(fd===1?'':'s')+'</span> <span class="muted">'+(extra.flame.last===today()?'· fed today':'· one action feeds it')+'</span><div class="muted" style="font-size:11px;margin-top:3px">The flame stays lit as long as any one of you acts each day.</div></div>';
  }
  var h='<div class="card" style="text-align:center"><div style="font-size:38px" aria-hidden="true">👥</div>'+
    '<h2 style="margin:4px 0 2px">'+esc(name)+'</h2>'+
    '<button class="chip sel" onclick="shareCircleInvite(\''+esc(code)+'\',\''+esc(name).replace(/'/g,'')+'\')">📤 Invite · '+esc(code)+'</button></div>'+flameLine;
  h+='<div class="grad g-forest" style="text-align:center"><div class="lbl">THIS WEEK, TOGETHER</div>'+
    '<div style="font-size:34px;font-weight:800;margin-top:4px">'+total+' action'+(total===1?'':'s')+'</div>'+
    '<div style="opacity:.9;font-size:13px;margin-top:2px">'+(total===0?'The week is young. First drop wins the crown 🌱':'Rain is only drops. These are yours.')+'</div></div>';
  var best=0;(rows||[]).forEach(function(m){if(m.week===wk&&(m.week_actions||0)>best)best=m.week_actions||0;});
  h+='<div class="card">'+(rows||[]).map(function(m){
    var wa=(m.week===wk)?(m.week_actions||0):0;
    var st=(typeof GROVE_STAGES!=='undefined'&&GROVE_STAGES[Math.min(m.stage||0,GROVE_STAGES.length-1)])?GROVE_STAGES[Math.min(m.stage||0,GROVE_STAGES.length-1)][1]:'🌱';
    return '<div class="settingrow"><span aria-hidden="true" style="font-size:20px">'+st+'</span>'+
      '<span style="font-weight:600">'+esc(m.name||'')+(wa===best&&best>0?' 🌟':'')+'</span>'+
      '<span style="margin-left:auto;color:var(--tx2);font-size:13px">🔥 '+(m.streak||0)+' · '+wa+'</span>'+
      (m.user_id&&me&&m.user_id!==me&&cid?'<button class="chip" style="margin-left:8px" onclick="cheer(\''+cid+'\',\''+m.user_id+'\')">💚 '+(ch[m.user_id]||0)+'</button>':'<span class="muted" style="margin-left:8px;font-size:12px">💚 '+(ch[m.user_id]||0)+'</span>')+'</div>';
  }).join('')+'</div>';
  h+='<p class="muted" style="font-size:12px;text-align:center">Groves grow side by side, never in each other\'s shade.</p>';
  return h;
}
function openCircleBoard(id,name,code){
  openSheet('<div class="muted" style="padding:20px;text-align:center">Gathering your circle…</div>');
  syncCircles(true);
  Promise.all([
    sbApi('/rest/v1/members?circle_id=eq.'+id+'&select=user_id,name,week,week_actions,streak,total_actions,stage&order=week_actions.desc').then(function(r){return r.ok?r.json():null;}),
    sbApi('/rest/v1/circles?id=eq.'+id+'&select=flame_start,flame_last').then(function(r){return r.ok?r.json():[];}).catch(function(){return [];}),
    sbApi('/rest/v1/cheers?circle_id=eq.'+id+'&week=eq.'+weekKey()+'&select=to_user').then(function(r){return r.ok?r.json():[];}).catch(function(){return [];})
  ]).then(function(all){
    var rows=all[0];
    var fl=(all[1]&&all[1][0])?{start:all[1][0].flame_start,last:all[1][0].flame_last}:null;
    var chm={};(all[2]||[]).forEach(function(x){chm[x.to_user]=(chm[x.to_user]||0)+1;});
    if(!rows){toast('Could not load the circle');return;}
    var wk=weekKey(),total=0;rows.forEach(function(m){if(m.week===wk)total+=(m.week_actions||0);});
    LS.set('circleHome',{id:id,name:name,code:code,total:total,n:rows.length,ts:Date.now()});
    var h=renderBoard(name,code,rows,{flame:fl,cheers:chm,me:(sbSession()||{}).user_id,cid:id});
    h+='<button class="btn ghost" onclick="leaveCircle(\''+id+'\',\''+esc(name).replace(/'/g,'')+'\')">Leave circle</button>';
    openSheet(h);
  }).catch(function(){toast('You seem to be offline');});
}
function openCircles(){
  if(!sbSignedIn()){openSheet('<div class="card" style="text-align:center"><div style="font-size:44px" aria-hidden="true">👥</div><h2 style="margin:6px 0 4px">Circles</h2><p class="muted">Sign in first (Me tab → Account) - then create a circle and invite your people with a 6-letter code.</p></div>');return;}
  var pend=LS.get('pendingJoin','')||'';
  var dn=displayName();
  var h='<div class="card" style="text-align:center"><div style="font-size:44px" aria-hidden="true">👥</div>'+
    '<h2 style="margin:6px 0 4px">Your circles</h2>'+
    '<p class="muted" style="margin:0">Private teams. Family, friends, classroom. No strangers, ever.</p></div>';
  var cs=myCircles();
  if(cs.length)h+=cs.map(function(c){return '<button class="card" style="width:100%;text-align:left;cursor:pointer;font-family:inherit;font-size:inherit;color:var(--tx)" onclick="openCircleBoard(\''+c.id+'\',\''+esc(c.name).replace(/'/g,'')+'\',\''+esc(c.code)+'\')"><b>👥 '+esc(c.name)+'</b> <span class="muted" style="font-size:12px">· '+esc(c.code)+'</span></button>';}).join('');
  h+='<h2 class="sec">Join a circle</h2><div class="card">'+
    '<div class="field"><label for="jc_code">Invite code</label><input id="jc_code" maxlength="6" style="text-transform:uppercase" placeholder="ABCDEF" value="'+esc(pend)+'"/></div>'+
    '<div class="field"><label for="jc_me">Your name in the circle</label><input id="jc_me" maxlength="24" placeholder="e.g. Yakir" value="'+esc(dn)+'"/></div>'+
    '<button class="btn" onclick="joinCircle()">Join</button></div>';
  h+='<h2 class="sec">Create a circle</h2><div class="card">'+
    '<div class="field"><label for="cc_name">Circle name</label><input id="cc_name" maxlength="30" placeholder="e.g. The Cohen family"/></div>'+
    '<div class="field"><label for="cc_me">Your name in the circle</label><input id="cc_me" maxlength="24" placeholder="e.g. Yakir" value="'+esc(dn)+'"/></div>'+
    '<button class="btn" onclick="createCircle()">Create + get invite code</button></div>';
  openSheet(h);
  fetchMyCircles().then(function(cs2){if(cs2.length!==cs.length)openCircles();}).catch(function(){});
}
function circlesCard(){
  var h='<h2 class="sec">Circles</h2><div class="card">';
  var cs=myCircles();
  if(!sbSignedIn()){
    h+='<div class="muted">👥 Grow together - sign in above, then create a circle and invite your people.</div>';
  } else if(!cs.length){
    h+='<div class="settingrow" style="cursor:pointer" onclick="openCircles()"><span>👥 Create your first circle</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>';
  } else {
    h+=cs.map(function(c){return '<div class="settingrow" style="cursor:pointer" onclick="openCircleBoard(\''+c.id+'\',\''+esc(c.name).replace(/'/g,'')+'\',\''+esc(c.code)+'\')"><span>👥 '+esc(c.name)+'</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>';}).join('')+
    '<div class="settingrow" style="cursor:pointer" onclick="openCircles()"><span class="muted">Manage / join another</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>';
  }
  return h+'</div>';
}
function circleHomeCard(){
  var c=LS.get('circleHome',null);
  if(!c||!c.id)return'';
  return '<button class="card" style="width:100%;text-align:left;cursor:pointer;font-family:inherit;font-size:inherit;color:var(--tx);display:flex;align-items:center;gap:10px" onclick="openCircleBoard(\''+c.id+'\',\''+esc(c.name).replace(/'/g,'')+'\',\''+esc(c.code||'')+'\')">'+
    '<span style="font-size:24px" aria-hidden="true">👥</span><span><b>'+esc(c.name)+'</b> · '+(c.total||0)+' action'+(c.total===1?'':'s')+' this week<div class="muted" style="font-size:12px">Tap to see your circle</div></span></button>';
}
function handleJoinLink(){
  if(typeof location==='undefined'||!location.search)return;
  var m=location.search.match(/[?&]join=([A-Za-z]{6})/);
  if(m){LS.set('pendingJoin',m[1].toUpperCase());
    try{history.replaceState(null,'',location.pathname);}catch(e){}
    setTimeout(function(){toast('👥 You have a circle invite - Me tab → Circles');},900);
  }
}
try{handleJoinLink();}catch(e){}

/* ---- gentle hooks into the core (wrap, never edit) ---- */
if(typeof doAction==='function'){
  var _doAction0=doAction;
  doAction=function(slug){_doAction0(slug);try{rainDrop(1);pulseBump(1);cloudAutoSave();syncCircles();}catch(e){}};
}
if(typeof finishLesson==='function'){
  var _finishLesson0=finishLesson;
  finishLesson=function(a,b){_finishLesson0(a,b);try{cloudAutoSave();}catch(e){}};
}
try{handleAuthReturn();}catch(e){}
try{if(typeof navigator!=='undefined'&&navigator.onLine!==false){getPulse();flushPulse();if(sbSignedIn()){fetchMyCircles();syncCircles();}}}catch(e){}
