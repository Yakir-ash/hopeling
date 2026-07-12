/* Hopeling - features.js (split from Hopeling.html, shared global scope, load order matters) */
/* ---------------- seasonal events (from content.json 'event' block) ---------------- */
var EVENT=null;
function activeEvent(){
  if(!EVENT||!EVENT.from||!EVENT.to)return null;
  var t=today();return (t>=EVENT.from&&t<=EVENT.to)?EVENT:null;
}
function bumpEvent(slug){
  var ev=activeEvent();if(!ev)return;
  var prog=state.eventProg[ev.id]=(state.eventProg[ev.id]||{});
  var doneAll=true;
  (ev.missions||[]).forEach(function(m){
    var d=prog[m.id]||0;
    if(d<m.n&&(!m.acts||m.acts.indexOf(slug)>=0)){
      d=prog[m.id]=d+1;
      if(d>=m.n){state.xp+=(m.xp||0);toast('\uD83C\uDFAF '+ev.name+': '+m.t+' \u2713 +'+(m.xp||0)+' XP');}
    }
    if((prog[m.id]||0)<m.n)doneAll=false;
  });
  if(doneAll&&(ev.missions||[]).length&&!state.eventBadges.some(function(b){return b[2]===ev.id})){
    state.eventBadges.push([(ev.badge&&ev.badge[0])||ev.emo||'\uD83C\uDF89',(ev.badge&&ev.badge[1])||ev.name,ev.id]);
    save();offerShare(((ev.badge&&ev.badge[0])||'\uD83C\uDF89')+' '+ev.name+' complete!','You finished every event mission and earned a limited badge only this event could give.');
  }
}
function eventHtml(){
  var ev=activeEvent();if(!ev)return'';
  if((state.eventBadges||[]).some(function(b){return b[2]===ev.id})){
    return '<div class="grad g-ocean" style="padding:12px 18px"><span aria-hidden="true">'+((ev.badge&&ev.badge[0])||ev.emo)+'</span> <span style="font-weight:600">'+esc(ev.name)+'</span> <span style="opacity:.85">· complete · badge earned ✓</span></div>';
  }
  var prog=state.eventProg[ev.id]||{};
  var daysLeft=daysBetween(today(),ev.to);
  var rows=(ev.missions||[]).map(function(m){var d=Math.min(prog[m.id]||0,m.n);var pct=Math.round(d/m.n*100);
    return '<div style="margin:8px 0"><div style="display:flex;font-size:13px"><span>'+(d>=m.n?'\u2705 ':'')+esc(m.t)+'</span><span style="margin-left:auto;opacity:.85">'+d+'/'+m.n+'</span></div>'+
      '<div style="height:7px;background:rgba(255,255,255,.25);border-radius:6px;margin-top:4px;overflow:hidden"><div style="height:100%;width:'+pct+'%;background:#fff"></div></div></div>';}).join('');
  return '<div class="grad g-ocean"><div class="lbl">'+(ev.emo||'\uD83C\uDF89')+' EVENT \u00b7 '+(daysLeft>0?daysLeft+' DAY'+(daysLeft===1?'':'S')+' LEFT':'LAST DAY')+'</div>'+
    '<div style="font-weight:700;font-size:17px;margin-top:4px">'+esc(ev.name)+'</div>'+
    (ev.desc?'<div style="font-size:13px;opacity:.9;margin-top:2px">'+esc(ev.desc)+'</div>':'')+rows+'</div>';
}

/* ---------------- travel mode: pack kindness (owner's idea, phases 2+3) ---------------- */
/* Checklists + destination guides come from content.json travel{} - content-only growth. */
var TRAVEL=null;
function travelChecklist(){return state.trip?((TRAVEL&&TRAVEL.checklists)||[]).filter(function(x){return x.id===state.trip.type})[0]:null;}
function openTravel(){
  if(!TRAVEL){toast('Travel guides are loading - try again in a moment');return;}
  var h='<div class="card" style="text-align:center"><div style="font-size:44px" aria-hidden="true">🧳</div>'+
    '<h2 style="margin:6px 0 4px">Traveling soon?</h2>'+
    '<p class="muted" style="margin:0">Pack kindness. Five minutes of prep makes your trip a gift to the wild instead of a weight on it.</p></div>';
  if(state.trip&&state.trip.doneAt){
    h+='<div class="card" style="text-align:center;background:var(--forest-c);border-color:transparent"><p style="margin:0;color:#0d3a26;font-weight:600">🌿 You\'re packed with kindness. Have a wild trip!</p>'+
      '<button class="btn" style="background:#fff" onclick="state.trip=null;save();openTravel()">Prep another trip</button></div>';
  } else if(state.trip){
    h+=tripChecklistHtml();
  } else {
    h+='<h2 class="sec">What kind of trip?</h2>'+((TRAVEL.checklists)||[]).map(function(c){
      return '<button class="card" style="width:100%;text-align:left;cursor:pointer;font-family:inherit;font-size:inherit;color:var(--tx)" onclick="startTrip(\''+c.id+'\')"><span style="font-size:22px" aria-hidden="true">'+c.emo+'</span> <b>'+esc(c.t)+'</b><div class="muted" style="margin-top:2px">'+c.items.length+' kind preparations</div></button>';
    }).join('');
  }
  if(((TRAVEL.destinations)||[]).length){
    h+='<h2 class="sec">🗺️ Destination guides</h2>'+TRAVEL.destinations.map(function(d2){
      return '<button class="card" style="width:100%;text-align:left;cursor:pointer;font-family:inherit;font-size:inherit;color:var(--tx)" onclick="openDestination(\''+d2.id+'\')"><span style="font-size:22px" aria-hidden="true">'+d2.emo+'</span> <b>'+esc(d2.name)+'</b> <span class="muted" style="font-size:12px">'+esc(d2.region||'')+'</span></button>';
    }).join('');
  }
  openSheet(h);
}
function startTrip(id){state.trip={type:id,date:today(),checked:{}};save();openTravel();}
function tripChecklistHtml(){
  var c=travelChecklist();if(!c)return'';
  var done=0;
  var rows=c.items.map(function(it){
    var on=!!state.trip.checked[it.id];if(on)done++;
    return '<button style="display:flex;gap:10px;width:100%;background:none;border:0;padding:9px 0;font-family:inherit;font-size:14px;color:var(--tx);cursor:pointer;text-align:left;border-bottom:0.5px solid var(--line);align-items:baseline" onclick="tripToggle(\''+it.id+'\')">'+
      '<span style="flex:none" aria-hidden="true">'+(on?'✅':'⬜')+'</span><span'+(on?' style="opacity:.55"':'')+'><b>'+esc(it.t)+'</b>'+(it.x?'<div class="muted" style="font-size:12px;font-weight:400">'+esc(it.x)+'</div>':'')+'</span></button>';
  }).join('');
  return '<div class="card"><div style="display:flex;align-items:baseline"><b>'+c.emo+' '+esc(c.t)+'</b><span style="margin-left:auto;color:var(--tx2);font-size:13px">'+done+'/'+c.items.length+'</span></div>'+
    '<div style="height:7px;background:var(--line);border-radius:6px;margin:8px 0 4px;overflow:hidden"><div style="height:100%;width:'+Math.round(done/c.items.length*100)+'%;background:var(--forest)"></div></div>'+
    rows+'<button class="btn ghost" onclick="if(confirm(\'Clear this trip prep?\')){state.trip=null;save();openTravel();}">Cancel this trip</button></div>';
}
function tripToggle(id){
  if(!state.trip)return;
  state.trip.checked[id]=!state.trip.checked[id];
  var c=travelChecklist();
  if(c&&!state.trip.doneAt&&c.items.every(function(it){return state.trip.checked[it.id];})){
    state.trip.doneAt=today();state.tripsDone=(state.tripsDone||0)+1;
    celebrateBurst();toast('🧳 Packed with kindness - have a wild trip!');
  }
  save();openTravel();
}
function openDestination(id){
  var d2=((TRAVEL&&TRAVEL.destinations)||[]).filter(function(x){return x.id===id})[0];if(!d2)return;
  var h='<div class="card" style="text-align:center"><div style="font-size:48px" aria-hidden="true">'+d2.emo+'</div>'+
    '<h2 style="margin:6px 0 2px">'+esc(d2.name)+'</h2><div class="muted">'+esc(d2.region||'')+'</div></div>';
  if((d2.watch||[]).length)h+='<h2 class="sec">👀 Watch for (kindly, from a distance)</h2><div class="row">'+d2.watch.map(function(w){
    return '<button class="chip" onclick="openSpecies(\''+encodeURIComponent(w)+'\',\''+(d2.cat||'')+'\')">'+esc(w)+'</button>';}).join('')+'</div>';
  if((d2["do"]||[]).length)h+='<h2 class="sec">💚 Do</h2><div class="card">'+d2["do"].map(function(x){return '<div style="padding:6px 0;font-size:14px">✓ '+esc(x)+'</div>';}).join('')+'</div>';
  if((d2.avoid||[]).length)h+='<h2 class="sec">Please avoid</h2><div class="card">'+d2.avoid.map(function(x){return '<div style="padding:6px 0;font-size:14px;color:#8a3b2e">✗ '+esc(x)+'</div>';}).join('')+'</div>';
  if(d2.tip)h+='<div class="grad g-terra"><div class="lbl">💡 GOLDEN TIP</div><div style="font-family:Georgia,serif;font-style:italic;margin-top:6px">'+esc(d2.tip)+'</div></div>';
  h+='<button class="btn ghost" onclick="openTravel()">← All travel guides</button>';
  openSheet(h);
}

/* ---------------- guardianship: one real species, yours ---------------- */
/* Roster from content.json guardians[]. Membership and promise, never guilt:
   the pledge celebrates the keeping, never punishes the keeper. */
var GUARDIANS=[];
function migrateCatCounts(){
  if(state.catCounts!==null&&state.catCounts!==undefined)return;
  var cc={};Object.keys(state.done||{}).forEach(function(slug){(ACT_CATS[slug]||[]).forEach(function(c){cc[c]=(cc[c]||0)+1;});});
  state.catCounts=cc;save();
}
function myWard(){if(!state.guardian)return null;return GUARDIANS.filter(function(g){return g.id===state.guardian.id;})[0]||null;}
function guardianActions(){
  var g=myWard();if(!g||!state.catCounts)return 0;
  var base=state.guardian.base||{},n=0;
  (g.cats||[]).forEach(function(c){n+=Math.max(0,(state.catCounts[c]||0)-(base[c]||0));});
  return n;
}
function guardianDays(){return state.guardian?daysBetween(state.guardian.date,today())+1:0;}
function openGuardians(){
  if(!GUARDIANS.length){toast('Guardianship is loading - try again in a moment');return;}
  var h='<div class="card" style="text-align:center"><div style="font-size:44px" aria-hidden="true">🛡️</div>'+
    '<h2 style="margin:6px 0 4px">Become a Guardian</h2>'+
    '<p class="muted" style="margin:0">Some species are down to their last few. Choose one. Act in its name. When good news comes about it, it will be your news too.</p>'+
    '<p style="font-family:Georgia,serif;font-style:italic;color:var(--forest);margin:12px 0 0">Guardians don\'t guard because they\'re certain.<br/>They guard because someone must.</p></div>';
  h+=GUARDIANS.map(function(g){
    return '<div class="card"><div style="display:flex;align-items:center;gap:12px">'+
      '<span style="font-size:34px" aria-hidden="true">'+g.emo+'</span>'+
      '<div style="flex:1"><div style="font-weight:700">'+esc(g.name)+'</div>'+
      '<div class="muted" style="font-size:12px;font-style:italic">'+esc(g.sci||'')+'</div>'+
      '<div style="color:#B3261E;font-size:12px;font-weight:600;margin-top:2px">'+esc(g.count)+'</div></div></div>'+
      '<p class="muted" style="margin:10px 0">'+esc(simpleText(g.story,g.story_simple))+'</p>'+
      '<button class="btn" onclick="openPledge(\''+g.id+'\')">Stand for the '+esc(g.name)+'</button></div>';
  }).join('');
  h+='<button class="btn ghost" onclick="openPledge(GUARDIANS[Math.floor(Math.random()*GUARDIANS.length)].id)">🍃 Let the wild choose for me</button>';
  openSheet(h);
}
var _holdTimer=null,_holdStart=0;
function openPledge(id){
  var g=GUARDIANS.filter(function(x){return x.id===id;})[0];if(!g)return;
  var h='<div class="card" style="text-align:center">'+
    '<div style="font-size:64px" aria-hidden="true">'+g.emo+'</div>'+
    '<h2 style="margin:6px 0 2px">'+esc(g.name)+'</h2>'+
    '<div class="muted" style="font-style:italic">'+esc(g.sci||'')+'</div>'+
    '<div style="color:#B3261E;font-weight:700;margin-top:8px">'+esc(g.count)+'</div>'+
    '<p class="muted" style="margin-top:12px">'+esc(simpleText(g.story,g.story_simple))+'</p></div>'+
    '<div class="card" style="text-align:center"><p style="font-family:Georgia,serif;font-style:italic;font-size:16px;line-height:1.7;margin:0 0 16px">I know how few remain.<br/>I will learn, act, and speak for them.<br/>I will be one of their guardians.</p>'+
    '<button class="btn holdbtn" style="margin-top:0" oncontextmenu="return false" onpointerdown="startHold(\''+g.id+'\')" onpointerup="cancelHold()" onpointerleave="cancelHold()"><span class="fill" id="holdfill"></span><span style="position:relative">Hold to take the pledge</span></button>'+
    '<div class="muted" style="font-size:12px;margin-top:8px">Press and hold - a promise takes a moment.</div></div>';
  openSheet(h);
}
function startHold(id){
  cancelHold();_holdStart=Date.now();
  _holdTimer=setInterval(function(){
    var pct=Math.min(100,(Date.now()-_holdStart)/1200*100);
    var f=document.getElementById('holdfill');if(f)f.style.width=pct+'%';
    if(pct>=100){cancelHold();pledge(id);}
  },50);
}
function cancelHold(){if(_holdTimer){clearInterval(_holdTimer);_holdTimer=null;}var f=document.getElementById('holdfill');if(f)f.style.width='0%';}
function pledge(id){
  var g=GUARDIANS.filter(function(x){return x.id===id;})[0];if(!g)return;
  state.catCounts=state.catCounts||{};
  var base={};(g.cats||[]).forEach(function(c){base[c]=state.catCounts[c]||0;});
  state.guardian={id:id,date:today(),base:base};save();
  celebrateBurst();openGuardian(true);
}
function openGuardian(fresh){
  var g=myWard();if(!g){openGuardians();return;}
  var gd=guardianDays(),ga=guardianActions();
  var h='<div class="card" style="text-align:center">'+
    (fresh===true?'<div class="lbl" style="color:var(--forest)">THE PLEDGE IS MADE</div>':'')+
    '<div style="font-size:64px" aria-hidden="true">'+g.emo+'</div>'+
    '<div class="lbl" style="color:var(--tx2);margin-top:4px">GUARDIAN OF THE</div>'+
    '<h2 style="margin:2px 0">'+esc(g.name)+'</h2>'+
    '<div style="color:#B3261E;font-weight:600;font-size:13px">'+esc(g.count)+'</div>'+
    '<div style="display:flex;gap:10px;justify-content:center;margin-top:14px">'+
    '<div class="metric" style="min-width:110px"><div class="v">'+gd+'</div><div class="m">day'+(gd===1?'':'s')+' as guardian</div></div>'+
    '<div class="metric" style="min-width:110px"><div class="v">'+ga+'</div><div class="m">action'+(ga===1?'':'s')+' in their name</div></div></div></div>'+
    '<div class="card"><div style="font-weight:600">🌍 Their story</div><p class="muted" style="margin:8px 0 0">'+esc(simpleText(g.story,g.story_simple))+'</p>'+
    '<button class="btn" onclick="openSpecies(\''+encodeURIComponent(g.wiki||g.name)+'\',\''+((g.cats||[])[0]||'')+'\')">Learn about them →</button>'+'</div>'+
    '<button class="btn" onclick="shareGuardian()">📤 Share my pledge</button>'+
    '<button class="btn ghost" onclick="if(confirm(\'Pass this guardianship on and choose a new ward? Your actions so far stay in your totals.\'))openGuardians()">Pass the torch</button>';
  openSheet(h);
}
function guardianNewsItem(){
  var g=myWard();if(!g||!(g.kw||[]).length)return null;
  for(var i=0;i<(NEWS||[]).length;i++){
    var n=NEWS[i],k=(n.url||n.t);
    if(state.guardianNews[k])continue;
    var t=(n.t||'').toLowerCase();
    if(g.kw.some(function(w){return t.indexOf(w.toLowerCase())>=0;}))return n;
  }
  return null;
}
function openGuardianNews(){
  var g=myWard(),n=guardianNewsItem();if(!g||!n)return;
  state.guardianNews[n.url||n.t]=1;save();
  celebrateBurst();
  var ga=guardianActions();
  var h='<div class="card" style="text-align:center"><div style="font-size:52px" aria-hidden="true">'+g.emo+'</div>'+
    '<div class="lbl" style="color:var(--forest)">NEWS ABOUT YOUR WARD</div>'+
    '<h2 style="margin:8px 0">'+esc(n.t)+'</h2>'+
    '<div class="muted" style="font-size:12px">'+esc(n.d||'')+(n.src?' · '+esc(n.src):'')+'</div>'+
    (n.url?'<a class="evidence" href="'+esc(n.url)+'" target="_blank" rel="noopener" style="display:inline-block;margin-top:8px">Read the story ↗</a>':'')+'</div>'+
    '<div class="card" style="text-align:center;background:var(--forest-c);border-color:transparent"><p style="margin:0;color:#0d3a26;font-weight:600">You\'ve taken '+ga+' action'+(ga===1?'':'s')+' as their guardian.<br/>This is what pulling looks like.</p></div>'+
    '<button class="btn" onclick="shareGuardian()">📤 Share this</button>'+
    '<button class="btn ghost" onclick="closeSheet();render()">Keep going</button>';
  openSheet(h);render();
}
function shareGuardian(){
  var g=myWard();if(!g)return;
  var cv=document.createElement('canvas');cv.width=1080;cv.height=1080;var x=cv.getContext('2d');
  var gr=x.createLinearGradient(0,0,1080,1080);gr.addColorStop(0,'#0B3D4C');gr.addColorStop(1,'#2E6B4F');x.fillStyle=gr;x.fillRect(0,0,1080,1080);
  x.textAlign='center';
  x.font='500 42px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.85)';x.fillText('GUARDIAN OF THE',540,160);
  x.font='280px -apple-system,Segoe UI,Arial';x.fillText(g.emo,540,500);
  x.fillStyle='#ffffff';x.font='700 80px -apple-system,Segoe UI,Arial';x.fillText(g.name.toUpperCase(),540,640);
  x.font='italic 40px Georgia,serif';x.fillStyle='#F0BE8C';x.fillText(g.count,540,706);
  x.font='500 40px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.92)';
  x.fillText(guardianDays()+' days · '+guardianActions()+' actions in their name',540,810);
  x.font='600 42px -apple-system,Segoe UI,Arial';x.fillStyle='#B2F1CC';x.fillText('Who do you guard?',540,910);
  x.font='500 36px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.85)';x.fillText('🌿 hopeling.app',540,990);
  cv.toBlob(function(blob){
    if(!blob){toast('Could not create image');return;}
    var file=new File([blob],'hopeling-guardian.png',{type:'image/png'});
    if(navigator.canShare&&navigator.canShare({files:[file]})){
      navigator.share({files:[file],title:'My guardianship',text:'I\'m a guardian of the '+g.name+' 🌿 Who do you guard?'}).catch(function(){});
    }else{
      var url=URL.createObjectURL(blob);var a=document.createElement('a');a.href=url;a.download='hopeling-guardian.png';document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(url)},1000);toast('Image saved - share it anywhere 📤');
    }
  },'image/png');
}

/* ---------------- grove companion (v23) ---------------- */
/* Grows with your current streak; rests (never dies) if you miss days. */
var GROVE_STAGES=[[0,'🌰','Sleeping seed'],[1,'🌱','Sprout'],[3,'🌿','Seedling'],[7,'🌳','Young tree'],[14,'🌳','Strong tree'],[30,'🌳','Flourishing tree'],[60,'🌲','Mighty grove'],[100,'🌲','Ancient grove']];
/* Friends arrive at streak milestones and stay forever (based on best-ever streak). */
var GROVE_FRIENDS=[[7,'🐦','a robin'],[14,'🐝','a bee'],[21,'🦋','a butterfly'],[30,'🐿️','a squirrel'],[45,'🦔','a hedgehog'],[60,'🦊','a fox'],[90,'🦉','an owl'],[120,'🦌','a deer']];
function groveStageIdx(s){var i=0;for(var j=0;j<GROVE_STAGES.length;j++)if(s>=GROVE_STAGES[j][0])i=j;return i;}
function groveBest(){return Math.max(state.streak,longestStreak());}
function groveFriendsEarned(){var b=groveBest();return GROVE_FRIENDS.filter(function(fr){return b>=fr[0]});}
function groveNextText(){
  var s=state.streak,b=groveBest(),opts=[];
  for(var j=0;j<GROVE_FRIENDS.length;j++)if(GROVE_FRIENDS[j][0]>b){var fd=GROVE_FRIENDS[j][0]-s;opts.push([fd,GROVE_FRIENDS[j][2]+' '+GROVE_FRIENDS[j][1]+' arrives in '+fd+' day'+(fd===1?'':'s')]);break;}
  for(var i=0;i<GROVE_STAGES.length;i++)if(GROVE_STAGES[i][0]>s){var d=GROVE_STAGES[i][0]-s;opts.push([d,GROVE_STAGES[i][1]+' '+GROVE_STAGES[i][2]+' in '+d+' day'+(d===1?'':'s')]);break;}
  if(!opts.length)return'';
  opts.sort(function(a,c){return a[0]-c[0]});
  return 'Next: '+opts[0][1];
}
function groveSceneHtml(big){
  var idx=groveStageIdx(state.streak),st=GROVE_STAGES[idx];
  var doneToday=state.last===today();
  var fr=groveFriendsEarned();
  var size=(big?44:34)+idx*6;
  return (fr.length?'<div class="friends" aria-hidden="true">'+fr.map(function(x){return x[1]}).join('')+'</div>':'')+
    '<div aria-hidden="true">'+(doneToday?'<span style="font-size:17px;vertical-align:top">✨</span>':'')+
    '<span class="tree" style="font-size:'+size+'px">'+st[1]+'</span>'+
    (doneToday?'<span style="font-size:17px;vertical-align:top">✨</span>':'')+'</div>';
}
function groveHtml(){
  var s=state.streak,st=GROVE_STAGES[groveStageIdx(s)];
  var doneToday=state.last===today();
  var caption;
  if(doneToday)caption='You showed up today - your grove is growing. 🌟';
  else if(s===0&&Object.keys(state.log).length)caption='Your grove is resting, not gone. One action wakes it up.';
  else if(s===0)caption='Plant your grove - one small action today.';
  else caption='One action today keeps it growing.';
  var nxt=groveNextText();
  return '<button class="card grove" onclick="openGrove()" aria-label="Your grove - tap for details">'+groveSceneHtml(false)+
    '<div style="font-weight:700;margin-top:6px">'+st[2]+(s>0?' · 🔥 '+s+' day'+(s===1?'':'s'):'')+'</div>'+
    '<div class="muted" style="margin-top:4px">'+caption+'</div>'+
    (nxt?'<div style="font-size:12px;color:var(--forest);margin-top:6px;font-weight:600">'+nxt+'</div>':'')+
    '</button>';
}
function openGrove(){
  var s=state.streak,b=groveBest(),idx=groveStageIdx(s);
  var h='<div class="card grove" style="cursor:default">'+groveSceneHtml(true)+
    '<div style="font-weight:700;margin-top:6px">'+GROVE_STAGES[idx][2]+'</div>'+
    '<div class="muted" style="margin-top:2px">🔥 '+s+' day streak · best '+b+'</div></div>';
  h+='<p class="muted">Your grove grows with your daily streak. Miss a day and it simply rests - it never dies, and its friends never leave. One action brings it back. 🌱</p>';
  h+='<h2 class="sec">Growth stages</h2><div class="card">'+GROVE_STAGES.map(function(st,i){
    return '<div class="settingrow"><span aria-hidden="true" style="font-size:20px'+(s>=st[0]?'':';filter:grayscale(1);opacity:.5')+'">'+st[1]+'</span><span'+(i===idx?' style="font-weight:700"':'')+'>'+st[2]+(i===idx?' · now':'')+'</span><span style="margin-left:auto;color:var(--tx2);font-size:12px">'+(st[0]===0?'start':st[0]+'+ days')+'</span></div>';
  }).join('')+'</div>';
  h+='<h2 class="sec">Grove friends</h2><p class="muted" style="margin-top:-2px">Each arrives at a streak milestone - and stays forever.</p>'+
    '<div class="card"><div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;text-align:center">'+GROVE_FRIENDS.map(function(fr){
    var got=b>=fr[0];
    return '<div><div style="font-size:26px'+(got?'':';filter:grayscale(1);opacity:.4')+'" aria-hidden="true">'+fr[1]+'</div><div class="muted" style="font-size:10px;margin-top:2px">'+(got?fr[2].replace(/^an? /,''):'day '+fr[0])+'</div></div>';
  }).join('')+'</div></div>';
  var rg=state.rings||[];
  if(rg.length){
    h+='<h2 class="sec">Tree rings</h2><p class="muted" style="margin-top:-2px">Every past streak leaves a ring - part of your tree\'s story, never lost.</p><div class="card">'+
      rg.map(function(r){return '<div class="settingrow"><span aria-hidden="true">\uD83E\uDEB5</span><span>'+r.n+'-day streak</span><span style="margin-left:auto;color:var(--tx2);font-size:12px">'+ringWhen(r.end)+'</span></div>';}).join('')+'</div>';
  }
  openSheet(h);
}

/* ---- photo hero: daily rotating category photo on the fact card ---- */
var _heroUrl=null;
function fillFactPhoto(){
  var el=document.getElementById('heroimg');if(!el)return;
  /* match the photo to today's fact's category (fact[2]); fall back to daily rotation */
  var f=FACTS[dailyIndex(FACTS.length,'f')];
  var c=(f&&f[2]&&CATS.filter(function(x){return x.slug===f[2]})[0])||CATS[dailyIndex(CATS.length,'p')];
  if(!c)return;
  heroTry(c,c.wiki||CAT_WIKI[c.slug]||c.name,function(){
    /* article had no usable image → fall back to the category's first curated species */
    var sp=catSpecies(c);if(sp&&sp.length)heroTry(c,sp[0],function(){});
  });
}
function heroTry(c,title,onFail){
  wikiGet(title,function(d){
    if(!d||!d.img){onFail();return;}
    /* Wikimedia refuses to upscale past the original size - try 640px, then the raw thumb. */
    var cands=[d.img.replace(/\/(\d+)px-/,'/640px-'),d.img].filter(function(u,i,a){return a.indexOf(u)===i});
    (function attempt(i){
      if(i>=cands.length){onFail();return;}
      var img=cands[i];
      function show(){
        var e2=document.getElementById('heroimg');if(!e2)return; /* user may have left Home */
        e2.style.backgroundImage='url("'+img+'")';e2.classList.add('show');
        var cap=document.getElementById('herocap');
        if(cap){cap.innerHTML=c.emo+' '+esc(d.t||c.name);cap.style.display='inline-block';cap.setAttribute('onclick','openCat(\''+c.slug+'\')');cap.setAttribute('aria-label','Photo: '+(d.t||c.name)+' - open category');}
        _heroUrl=img;
      }
      if(_heroUrl===img){show();return;} /* already loaded this session - no flash */
      var pre=new Image();pre.onload=show;pre.onerror=function(){attempt(i+1);};pre.src=img;
    })(0);
  });
}

