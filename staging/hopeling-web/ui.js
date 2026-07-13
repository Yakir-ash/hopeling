/* Hopeling - ui.js (split from Hopeling.html, shared global scope, load order matters) */
/* ---------------- actions ---------------- */
var tab='home';
function toast(msg){var t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');setTimeout(function(){t.classList.remove('show')},1900);}
/* Explain-simply: show the kid-friendly variant when the toggle is on and one exists. */
function kidOrSimple(){return !!(state.simple||state.kid);}
function simpleText(full,simple){return (kidOrSimple()&&simple)?simple:(full||simple||'');}
function simpleChip(ctx){
  if(state.kid)return'';
  return '<button class="chip'+(state.simple?' sel':'')+'" style="margin-bottom:10px" onclick="toggleSimple('+ctx+')" aria-pressed="'+(state.simple?'true':'false')+'">🧒 '+(state.simple?'Explain simply: on':'Explain simply')+'</button>';
}
function toggleSimpleTop(){if(state.kid){toast('🧒 Kid mode is on - switch it in the Me tab');return;}state.simple=!state.simple;save();render();toast(state.simple?'🧒 Simple mode on':'Simple mode off');}
function toggleSimple(kind,slug,i){
  state.simple=!state.simple;save();
  toast(state.simple?'🧒 Simple mode on':'Simple mode off');
  if(kind==='lesson')openLesson(slug,i);
  else if(kind==='cat')catTab(slug,i);
}
function celebrateBurst(){
  try{
    if(navigator.vibrate)navigator.vibrate(35);
    if(typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    var host=document.createElement('div');host.className='burst';host.setAttribute('aria-hidden','true');
    var glyphs=['🌱','✨','🍃','💚','🌿'];
    for(var i=0;i<18;i++){
      var sp=document.createElement('span');sp.textContent=glyphs[i%glyphs.length];
      var ang=Math.random()*2*Math.PI,dist=60+Math.random()*120;
      sp.style.left='50%';sp.style.top='55%';
      sp.style.setProperty('--dx',Math.cos(ang)*dist+'px');
      sp.style.setProperty('--dy',(Math.sin(ang)*dist-80)+'px');
      sp.style.setProperty('--rot',(Math.random()*240-120)+'deg');
      sp.style.animationDelay=(Math.random()*120)+'ms';
      host.appendChild(sp);
    }
    document.body.appendChild(host);
    setTimeout(function(){if(host.parentNode)host.parentNode.removeChild(host);},1200);
  }catch(e){}
}
function doAction(slug){
  var a=getAct(slug);if(!a)return;
  var prevLvl=levelForXp(state.xp);
  var first=!state.done[slug];var gain=first?10:5;state.xp+=gain;
  state.done[slug]=true;logToday();
  state.catCounts=state.catCounts||{};(ACT_CATS[slug]||[]).forEach(function(c){state.catCounts[c]=(state.catCounts[c]||0)+1;});
  if(a.metric&&a.val)state.totals[a.metric]=(state.totals[a.metric]||0)+a.val;
  touchStreak();bumpMissions('action',slug);bumpEvent(slug);checkBadges();save();syncTop();
  var extra=state._freezeEarned?' · ❄️ Freeze earned!':(state._freezeUsed?' · ❄️ Freeze used':'');
  if(state._newFriend){extra+=' · '+state._newFriend+' joined your grove!';state._newFriend=null;}
  state._freezeEarned=false;state._freezeUsed=false;
  celebrateBurst();toast('✓ +'+gain+' XP · Thank you! 🌱'+extra);render();maybeCelebrate(prevLvl);
}
function doChallenge(){
  if(state.chDone===today()){toast('Challenge already done today ✅');return;}
  var ch=CHALLENGES[dailyIndex(CHALLENGES.length,'c')];
  state.chDone=today();state.xp+=ch[1];logToday();touchStreak();bumpMissions('action','');bumpEvent('');checkBadges();save();syncTop();
  celebrateBurst();toast('🏆 Challenge done! +'+ch[1]+' XP');render();
}
function badgeDefs(){
  var acts=Object.keys(state.done).length,lvl=levelForXp(state.xp),best=Math.max(state.streak,longestStreak());
  var defs=[
   ['🌱','First step',Math.min(acts,1),1,'Complete your very first action. You\'re on your way.','action'],
   ['⚡','Action Hero',Math.min(acts,5),5,'Complete 5 different actions from the Act tab.','action'],
   ['🌟','Changemaker',Math.min(acts,12),12,'Complete 12 different actions - real, varied impact.','action'],
   ['🔥','Week of Hope',Math.min(best,7),7,'Keep a 7-day streak going. One action a day.','streak'],
   ['☀️','Month of Hope',Math.min(best,30),30,'Reach a 30-day streak. A true daily habit.','streak'],
   ['🛡️','Guardian',Math.min(lvl,5),5,'Reach Level 5 by earning XP from actions and lessons.','level']
  ];
  COURSES.forEach(function(c){var done=c.lessons.filter(function(l,i){return state.lessons[c.slug+i]}).length;defs.push([c.badge,c.t+' course',done,c.lessons.length,'Finish all '+c.lessons.length+' lessons in the “'+c.t+'” course.','course',c.slug]);});
  (state.eventBadges||[]).forEach(function(b){defs.push([b[0],b[1],1,1,'Limited event badge - earned by completing every mission of '+b[1]+'.','event']);});
  defs.push(['🤝','The Pledge',state.guardian?1:0,1,'Swear guardianship over one of Earth\'s rarest species, from the Me tab.','guard']);
  defs.push(['🧳','Trip Ready',Math.min(state.tripsDone||0,1),1,'Complete a pre-trip kindness checklist before an adventure (Me tab).','travel']);
  var aev=activeEvent();
  if(aev&&!(state.eventBadges||[]).some(function(b){return b[2]===aev.id})){
    var ep=state.eventProg[aev.id]||{};var dm=(aev.missions||[]).filter(function(m){return (ep[m.id]||0)>=m.n}).length;
    defs.push([(aev.badge&&aev.badge[0])||aev.emo,(aev.badge&&aev.badge[1])||aev.name,dm,(aev.missions||[]).length||1,'Limited-time: complete all '+((aev.missions||[]).length)+' '+aev.name+' missions before '+aev.to+'.','event']);
  }
  return defs;
}
function badgeGalleryHtml(){
  return badgeDefs().map(function(d,i){var got=d[2]>=d[3];
    return '<button onclick="openBadge('+i+')" style="background:none;border:0;cursor:pointer;font-family:inherit;padding:0'+(got?'':';opacity:.5')+'"><div style="font-size:26px'+(got?'':';filter:grayscale(1)')+'" aria-hidden="true">'+d[0]+'</div>'+
      '<div style="font-size:11px;margin-top:2px;color:var(--tx)">'+esc(d[1])+'</div>'+
      '<div class="muted" style="font-size:10px">'+(got?'Earned ✓':d[2]+'/'+d[3])+'</div></button>';}).join('');
}
function openBadge(i){
  var d=badgeDefs()[i];if(!d)return;var got=d[2]>=d[3],pct=Math.round(d[2]/d[3]*100);
  var h='<div class="card" style="text-align:center"><div style="font-size:56px'+(got?'':';filter:grayscale(1);opacity:.6')+'" aria-hidden="true">'+d[0]+'</div>'+
    '<h2 style="margin:8px 0 2px">'+esc(d[1])+'</h2>'+
    '<div class="'+(got?'':'muted')+'" style="color:'+(got?'var(--forest)':'var(--tx2)')+';font-weight:600">'+(got?'Earned ✓':d[2]+' / '+d[3])+'</div>'+
    '<p class="muted" style="margin-top:10px">'+d[4]+'</p>'+
    (got?'':'<div style="height:7px;background:var(--line);border-radius:6px;margin-top:10px;overflow:hidden"><div style="height:100%;width:'+pct+'%;background:var(--forest)"></div></div>')+
    (got?'':'<button class="btn" style="margin-top:14px" onclick="'+(d[5]==='course'?'openCourse(\''+d[6]+'\')':''+(d[5]==='guard'?'openGuardians()':d[5]==='travel'?'openTravel()':'closeSheet();go(\''+(d[5]==='streak'||d[5]==='level'||d[5]==='event'?'home':'act')+'\')')+'')+'">'+(d[5]==='course'?'Go to course':'Take an action')+'</button>')+
    '</div>';
  openSheet(h);
}
function offerShare(title,msg){
  openSheet('<div class="card" style="text-align:center"><div style="font-size:48px" aria-hidden="true">🎉</div>'+
    '<h2 style="margin:8px 0 4px">'+title+'</h2><p class="muted">'+msg+'</p>'+
    '<button class="btn" onclick="shareImpact()">📤 Share my impact</button>'+
    '<button class="btn ghost" onclick="closeSheet()">Keep going</button></div>');
}
function maybeCelebrate(prevLvl){
  var ms=state.milestones||(state.milestones={});
  if(state.streak>=7&&state.streak%7===0&&!ms['s'+state.streak]){ms['s'+state.streak]=1;save();groveGlow();offerShare(state.streak+'-day streak! 🔥','That\'s '+state.streak+' straight days of action for wildlife. Worth showing off.');return;}
  var lvl=levelForXp(state.xp);
  if(lvl>prevLvl&&lvl>=2&&!ms['l'+lvl]){ms['l'+lvl]=1;save();offerShare('Level '+lvl+' - '+(LEVEL_NAMES[lvl-1]||'Champion')+'!','You leveled up. Small actions, adding up.');}
}
function checkBadges(){
  var n=Object.keys(state.done).length,lvl=levelForXp(state.xp);
  if(n>=1)state.badges['🌱']='First step';
  if(n>=5)state.badges['⚡']='Action Hero';
  if(n>=12)state.badges['🌟']='Changemaker';
  if(state.streak>=7)state.badges['🔥']='Week of Hope';
  if(state.streak>=30)state.badges['☀️']='Month of Hope';
  if(lvl>=5)state.badges['🛡️']='Guardian';
}
function syncTop(){document.getElementById('topStreak').textContent='🔥 '+state.streak;
  var sb=document.getElementById('simpleBtn');if(sb){sb.className='tbtn'+(kidOrSimple()?' on':'');sb.setAttribute('aria-pressed',kidOrSimple()?'true':'false');}}

function render(){
  syncTop();
  var el=document.getElementById('app'),h='';
  if(tab==='home'){
    var f=FACTS[dailyIndex(FACTS.length,'f')];
    var aslug=todayActionSlug();var a=getAct(aslug);
    var ch=CHALLENGES[dailyIndex(CHALLENGES.length,'c')];
    /* --- core loop: grove -> fact -> action -> challenge --- */
    var _dt=new Date();h+='<div class="mhdate">'+_dt.toLocaleDateString('en-US',{weekday:'long',month:'long',day:'numeric'}).toUpperCase()+'</div>';
    var _hr=_dt.getHours();
    h+='<div class="greet">'+(_hr<5?'The night watch \ud83c\udf19':_hr<12?'Good morning \ud83c\udf05':_hr<18?'Good afternoon \u2600\ufe0f':'Good evening \ud83c\udf19')+(state.streak>0?' \u00b7 day '+state.streak+' of your streak':'')+'</div>';
    if(repairable())h+='<div class="installbar" style="background:var(--terra);color:#4a2c10"><span aria-hidden="true">🔥</span><span>You missed a day - repair your '+state.streak+'-day streak?</span><button class="chip sel" style="margin-left:auto;background:#4a2c10;color:#fff" onclick="repairStreak()">Repair</button></div>';
    var gn=guardianNewsItem();
    if(gn){
      var gwd=myWard();
      h+='<button class="grad g-terra" style="width:100%;border:0;text-align:left;font-family:inherit;font-size:inherit;cursor:pointer" onclick="openGuardianNews()">'+
        '<div class="lbl">'+gwd.emo+' NEWS ABOUT YOUR WARD</div>'+
        '<div style="font-weight:700;font-size:16px;margin-top:4px">Something happened for the '+esc(gwd.name)+'.</div>'+
        '<div style="font-size:13px;margin-top:2px">And you helped pull. Tap - this one is yours.</div></button>';
    }
    h+=groveHtml();
    h+=eventHtml();
        h+='<div class="grad g-forest hero" onclick="openPlate()" style="cursor:pointer"><div class="heroimg" id="heroimg"></div><div class="heroscrim"></div>'+
       '<div class="herobody"><div class="lbl">TODAY\'S FACT</div><div class="fact">'+esc(simpleText(f[0],f[3]))+'</div><div class="lbl" style="margin-top:8px">- '+f[1]+'</div>'+
       '<button class="herocap" id="herocap"></button></div></div>';
    h+='<h2 class="sec">Today\'s action</h2>'+actionCardHtml(aslug,a);
    h+=(typeof circleHomeCard==='function'?circleHomeCard():'');
    h+=(typeof pulseCard==='function'?pulseCard():'');
    /* --- below the fold: banners + extras --- */
    if(installEvt&&!isStandalone())h+='<div class="installbar"><span aria-hidden="true">📲</span><span>Install Hopeling for offline use.</span><button class="chip sel" style="margin-left:auto" onclick="doInstall()">Install</button></div>';
    var rs=weekAgoStats();
    if(state.recapWeek!==weekKey()&&rs[0]>0){
      h+='<div class="grad g-terra"><div class="lbl">YOUR WEEK IN REVIEW</div>'+
        '<div style="font-size:18px;font-weight:700;margin-top:6px">'+rs[0]+' action'+(rs[0]===1?'':'s')+' across '+rs[1]+' day'+(rs[1]===1?'':'s')+' 🌱</div>'+
        '<div style="margin-top:4px;font-size:13px">Every one of them counted. New week, fresh start.</div>'+
        '<div style="display:flex;gap:8px;margin-top:10px"><button class="chip sel" onclick="shareImpact()">📤 Share</button>'+
        '<button class="chip" style="background:rgba(0,0,0,.15);color:inherit;border-color:transparent" onclick="dismissRecap()">Nice ✓</button></div></div>';
    }
    if(backupDue())h+='<div class="installbar"><span aria-hidden="true">💾</span><span>Protect your streak - save a backup. Browsers can clear app data.</span><button class="chip sel" style="margin-left:auto" onclick="exportProgress()">Back up</button></div>';
    h+=missionsHtml();
    if(!state.spirit&&!state.spiritDismissed){
      h+='<div class="card" style="display:flex;align-items:center;gap:10px"><span style="font-size:26px" aria-hidden="true">🦊</span><div style="flex:1"><div style="font-weight:600">What\'s your spirit species?</div><div class="muted">7 questions, 60 seconds.</div></div><button class="chip sel" onclick="openQuiz()">Find out</button><button class="chip" aria-label="Not now" onclick="state.spiritDismissed=true;save();render()">✕</button></div>';
    }
    var newsList=(NEWS&&NEWS.length)?NEWS:STORIES.map(function(sx){return{tag:sx[0],t:sx[1],x:sx[2]}});
    if(newsList.length){
      h+='<h2 class="sec">🗞️ Good news</h2>'+newsList.slice(0,3).map(function(n){
        return '<div class="card"><div style="color:var(--forest);font-weight:600;font-size:13px">'+esc(n.tag||'🎉')+(n.d?' <span class="muted" style="font-weight:400">· '+esc(newsAge(n.d))+'</span>':'')+'</div>'+
          '<div style="font-weight:600;margin-top:6px">'+esc(n.t)+'</div><div class="muted" style="margin-top:4px">'+esc(n.x)+'</div>'+
          (n.url?'<a class="evidence" href="'+esc(n.url)+'" target="_blank" rel="noopener" style="display:inline-block;margin-top:6px">'+esc(n.src||'Read more')+' ↗</a>':(n.src?'<div class="evidence" style="margin-top:6px">- '+esc(n.src)+'</div>':''))+
          '</div>';}).join('');
    }
    var hopePool=[];CATS.forEach(function(hc){(hc.hope||[]).forEach(function(hp){hopePool.push([hc.emo,hc.name,hp[0],hp[1],hc.slug]);});});
    if(hopePool.length){var sp=hopePool[dailyIndex(hopePool.length,'h')];
      h+='<button class="grad g-ocean" style="width:100%;border:0;text-align:left;font-family:inherit;font-size:inherit;cursor:pointer" onclick="openCat(\''+sp[4]+'\')">'+
        '<div class="lbl">'+sp[0]+' HOPE SPOTLIGHT · '+esc(sp[1]).toUpperCase()+'</div>'+
        '<div style="font-weight:600;margin-top:6px">'+sp[2]+'</div>'+
        '<div style="opacity:.9;font-size:13px;margin-top:4px">'+sp[3]+'</div>'+
        '<div class="lbl" style="margin-top:8px">TAP TO EXPLORE →</div></button>';}
  }
  else if(tab==='explore'){
    var GROUPS=[['🌊 Oceans & marine life',['oceans','coral-reefs','sea-turtles','whales','sharks','dolphins','penguins','polar-bears']],
                ['🌳 Land & wild',['forests','freshwater','wetlands','elephants','gorillas','orangutans','lions','tigers','pandas','rhinos','wolves','foxes','frogs']],
                ['🏡 Closer to home',['birds','bees','butterflies','bats','dogs','cats','farm-animals']]];
    var placed={};
    h+='<h2 class="sec" style="margin-top:4px">Explore</h2>';
    GROUPS.forEach(function(g){
      var cs=g[1].map(function(sl){placed[sl]=1;return CATS.filter(function(c){return c.slug===sl})[0];}).filter(Boolean);
      if(!cs.length)return;
      h+='<h2 class="sec" style="font-size:14px;color:var(--tx2)">'+g[0]+'</h2><div class="grid">'+cs.map(function(c){return '<button class="cat" onclick="openCat(\''+c.slug+'\')"><div class="emo" aria-hidden="true">'+c.emo+'</div><div class="nm">'+c.name+'</div></button>'}).join('')+'</div>';
    });
    var rest=CATS.filter(function(c){return !placed[c.slug]});
    if(rest.length)h+='<h2 class="sec" style="font-size:14px;color:var(--tx2)">🌟 More</h2><div class="grid">'+rest.map(function(c){return '<button class="cat" onclick="openCat(\''+c.slug+'\')"><div class="emo" aria-hidden="true">'+c.emo+'</div><div class="nm">'+c.name+'</div></button>'}).join('')+'</div>';
  }
  else if(tab==='act'){
    h+='<h2 class="sec" style="margin-top:4px">⚡ Act</h2>';
    h+='<div class="row">'+[[0,'All'],[1,'Easy'],[2,'Medium'],[3,'High impact']].map(function(d){return '<button class="chip'+(actFilter.dif===d[0]?' sel':'')+'" onclick="setDif('+d[0]+')">'+d[1]+'</button>'}).join('')+'</div>';
    h+='<div class="row" style="margin-top:6px">'+[['','Any'],['home','🏠 Home'],['outdoor','🌳 Outdoor'],['online','💻 Online'],['financial','💰 Give']].map(function(m){return '<button class="chip'+(actFilter.mod===m[0]?' sel':'')+'" onclick="setMod(\''+m[0]+'\')">'+m[1]+'</button>'}).join('')+'</div><div style="height:8px"></div>';
    h+='<button class="btn ghost" style="margin-bottom:10px" onclick="openAddAction()">＋ Add your own action</button>';
    var any=false;
    var _slugs=allActSlugs();
    if(state.kid)_slugs.sort(function(x,y){return (isKidOk(y)?1:0)-(isKidOk(x)?1:0);});
    _slugs.forEach(function(slug){var a=getAct(slug);
      if(actFilter.dif&&a.diff!==actFilter.dif)return;
      if(actFilter.mod&&a.mod!==actFilter.mod)return;
      any=true;h+=actionCardHtml(slug,a);});
    if(!any)h+='<div class="muted">No actions match - try clearing a filter.</div>';
  }
  else if(tab==='learn'){
    h+='<h2 class="sec" style="margin-top:4px">🎓 Learn</h2>'+COURSES.map(function(c){
      var done=c.lessons.filter(function(l,i){return state.lessons[c.slug+i]}).length;
      return '<button class="card" style="width:100%;text-align:left;cursor:pointer" onclick="openCourse(\''+c.slug+'\')"><div style="font-weight:600">'+c.t+' '+(done===c.lessons.length?'✅':'')+'</div><div class="muted" style="margin-top:4px">'+c.d+'</div><div style="color:var(--forest);font-size:12px;margin-top:8px">'+c.lessons.length+' lessons · '+done+'/'+c.lessons.length+' done</div></button>'}).join('');
  }
  else if(tab==='me'){
    var lvl=levelForXp(state.xp);
    h+='<div class="grad g-terra"><div style="font-size:17px;font-weight:700">Level '+lvl+' · '+(LEVEL_NAMES[lvl-1]||'Champion')+'</div><div style="margin-top:2px">'+state.xp+' XP</div><div style="margin-top:8px">🔥 '+state.streak+' day'+(state.streak===1?'':'s')+'</div></div>';
    if(Object.keys(state.log).length>=14){
      h+='<h2 class="sec">Your year of action</h2><div class="card">'+graphHtml()+'</div>';
    } else {
      h+='<div class="muted" style="margin:10px 2px 0;font-size:12px">📈 Your year-of-action graph unlocks after two weeks of activity.</div>';
    }
    var mets=[['plastic_kg','♻️ Plastic avoided','kg'],['trees','🌳 Trees',''],['money','💚 Donated','$'],['carbon_kg','🌍 CO₂ saved','kg'],['animals','🐾 Animals helped',''],['generic','⭐ Actions logged','']];
    h+='<div class="grid" style="grid-template-columns:1fr 1fr">'+mets.map(function(m){var v=state.totals[m[0]]||0;var disp=m[2]==='$'?'$'+round(v):(round(v)+' '+m[2]).trim();return '<div class="metric"><div class="v">'+disp+'</div><div class="m">'+m[1]+'</div></div>'}).join('')+'</div>';
    h+='<div style="display:flex;gap:10px;margin-top:12px"><button class="btn" style="margin-top:0" onclick="shareImpact()">📤 Share impact</button><button class="btn ghost" style="margin-top:0" onclick="openLogImpact()">＋ Log impact</button></div>';
    var mw=myWard();
    h+='<h2 class="sec">Your journey</h2><div class="card">'+
      '<div class="settingrow" style="cursor:pointer" onclick="'+(state.spirit&&SPIRITS[state.spirit.id]?'showSpirit(\''+state.spirit.id+'\')':'openQuiz()')+'"><span>'+(state.spirit&&SPIRITS[state.spirit.id]?SPIRITS[state.spirit.id].e+' Spirit: '+SPIRITS[state.spirit.id].n:'🦊 Find your spirit species')+'</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>'+
      (mw?'<div class="settingrow" style="cursor:pointer" onclick="openGuardian()"><span>'+mw.emo+' Guardian of the '+esc(mw.name)+' · '+guardianDays()+' day'+(guardianDays()===1?'':'s')+'</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>':'')+
      '<div class="settingrow" style="cursor:pointer" onclick="openTravel()"><span>🧳 '+(state.trip&&!state.trip.doneAt?'Trip prep in progress - continue':'Traveling soon? Pack kindness')+'</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>'+
      '<div class="settingrow" style="cursor:pointer" onclick="openCalc()"><span>🔮 Impact calculator</span><span style="margin-left:auto;color:var(--tx2)" aria-hidden="true">→</span></div>'+
      '</div>';
    h+='<h2 class="sec">Badges</h2><div class="card"><div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;text-align:center">'+badgeGalleryHtml()+'</div></div>';
    h+=(typeof accountCard==='function'?accountCard():'');
    h+=(typeof circlesCard==='function'?circlesCard():'');
    h+='<h2 class="sec">Settings</h2><div class="card">'+
       '<div class="settingrow"><span>🌙 Dark mode</span><button class="chip'+(document.documentElement.getAttribute('data-theme')==='dark'?' sel':'')+'" style="margin-left:auto" onclick="toggleTheme()">'+(document.documentElement.getAttribute('data-theme')==='dark'?'On':'Off')+'</button></div>'+
       '<div class="settingrow"><span>🔔 Daily reminder</span><button class="chip'+(state.remind?' sel':'')+'" style="margin-left:auto" onclick="toggleRemind()">'+(state.remind?'On':'Off')+'</button></div>'+
       '<div class="settingrow"><span>🧒 Explain simply</span><button class="chip'+(state.simple?' sel':'')+'" style="margin-left:auto" onclick="state.simple=!state.simple;save();render()">'+(state.simple?'On':'Off')+'</button></div>'+
       '<div class="settingrow"><span>📅 Calendar reminder</span><button class="chip" style="margin-left:auto" onclick="downloadReminder()">Add</button></div>'+
       '<div class="settingrow"><span>❄️ Streak freezes</span><span style="margin-left:auto;color:var(--tx2)">'+(state.freezes||0)+' (earn 1 every 7-day streak)</span></div>'+
       '<div class="settingrow"><span>📤 Back up progress</span><button class="chip" style="margin-left:auto" onclick="exportProgress()">Export</button></div>'+
       '<div class="settingrow"><span>📥 Restore progress</span><button class="chip" style="margin-left:auto" onclick="document.getElementById(\'importfile\').click()">Import</button></div>'+
       '<div class="settingrow" style="display:block"><div class="muted">Reminders nudge you when you open the app and haven\'t acted today. For a reminder that works even when the app is closed, add the calendar reminder - it creates a daily event in your phone\'s calendar. Back up your progress so it survives clearing your browser or switching phones.</div></div>'+
       '</div>';
    h+='<button class="btn ghost" onclick="resetAll()">Reset my progress</button>';
    h+='<div class="muted" style="text-align:center;margin-top:14px">Hopeling '+DISPLAY_V+' · '+(contentUpdated?'content updated '+contentUpdated+' · ':'')+'made with hope 🌿 · <a class="evidence" href="../privacy.html" target="_blank" rel="noopener">privacy</a><br/>© 2026 Hopeling · All rights reserved</div>';
  }
  el.innerHTML=h;
  if(tab==='home'){fillFactPhoto();maybeVisitor();}
  // auto-scroll impact graph to most recent
  var gw=document.getElementById('graphwrap');if(gw)gw.scrollLeft=gw.scrollWidth;
}
function actionCardHtml(slug,a){
  var done=state.done[slug];
  return '<div class="card"><div style="font-weight:600;cursor:pointer" onclick="openAction(\''+slug+'\')">'+esc(a.t)+'</div>'+
    '<div class="muted" style="margin:6px 0">'+esc(simpleText(a.why,a.why_simple))+'</div>'+
    '<div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">'+pips(a.diff)+
    '<span class="chip" style="cursor:default">'+a.min+' min</span><span class="chip" style="cursor:default">'+a.cost+'</span>'+(state.kid&&!isKidOk(slug)?'<span class="chip" style="cursor:default;background:var(--terra);color:#4a2c10;border-color:transparent">👨‍👧 With a grown-up</span>':'')+'</div>'+
    '<button class="btn'+(done?' done':'')+'" onclick="doAction(\''+slug+'\')">'+(done?'✓ Done - do it again':'Do it')+'</button></div>';
}

var actFilter={dif:0,mod:''};
function setDif(d){actFilter.dif=d;render();}
function setMod(m){actFilter.mod=m;render();}

/* sheets */
function openSheet(html){hpt(6);var dm=document.getElementById('sheetdim');if(!dm){dm=document.createElement('div');dm.id='sheetdim';dm.className='sheetdim';dm.onclick=function(){closeSheet();};document.body.appendChild(dm);}dm.classList.add('on');var s=document.getElementById('sheet');s.innerHTML='<div class="grab"></div><div class="shead"><button onclick="closeSheet()" aria-label="Back">'+ICO.back+'</button></div><div class="wrap">'+html+'</div>';if(!s.classList.contains('open')){s.classList.add('open');try{history.pushState({wh:'sheet'},'');}catch(e){}}s.scrollTop=0;}
function closeSheet(fromPop){var dm=document.getElementById('sheetdim');if(dm)dm.classList.remove('on');var s=document.getElementById('sheet');if(!s.classList.contains('open'))return;s.classList.remove('open');if(!fromPop&&history.state&&history.state.wh==='sheet'){try{history.back();}catch(e){}}}
window.addEventListener('popstate',function(){closeSheet(true);});
function openCat(slug){
  var c=CATS.filter(function(x){return x.slug===slug})[0];if(!c)return;
  var tabs=['Overview','Species','Threats & Hope','Act','Help'];
  var body='<div style="text-align:center"><div style="font-size:40px" aria-hidden="true">'+c.emo+'</div><h2 style="margin:4px 0">'+c.name+'</h2>'+iucnHtml(c.iucn)+'</div>';
  body+='<div class="tabbar">'+tabs.map(function(t,i){return '<button class="'+(i===0?'on':'')+'" onclick="catTab(\''+slug+'\','+i+',this)">'+t+'</button>'}).join('')+'</div><div id="catBody"></div>';
  openSheet(body);catTab(slug,0);
}
function emptyMsg(m){return '<div class="muted" style="padding:8px">'+m+'</div>';}
function catTab(slug,i,btn){
  if(btn){var p=btn.parentNode.children;for(var k=0;k<p.length;k++)p[k].className='';btn.className='on';}
  var c=CATS.filter(function(x){return x.slug===slug})[0];var b=document.getElementById('catBody'),h='';
  if(i===0){
    h='<p style="line-height:1.6">'+(c.overview||c.sum||'')+'</p>';
    if(c.sci_simple)h+=simpleChip("'cat','"+slug+"',0");
    if(c.science||c.sci_simple)h+='<div class="card">🔬 '+simpleText(c.science,c.sci_simple)+'</div>';
    if(c.stats&&c.stats.length)h+='<div class="grid" style="grid-template-columns:1fr 1fr;margin-bottom:6px">'+c.stats.map(function(st){return '<div class="metric"><div class="v" style="font-size:18px">'+st[1]+'</div><div class="m">'+st[0]+'</div></div>'}).join('')+'</div>';
    if(c.facts&&c.facts.length)h+='<h2 class="sec">Did you know?</h2>'+c.facts.map(function(f){return '<div class="card">'+f[0]+'<div class="evidence" style="margin-top:4px">- '+f[1]+'</div></div>'}).join('');
    h+='<div id="wikiOv"></div>';
  }
  else if(i===1){h=speciesListHtml(c);}
  else if(i===2){
    var th=(c.threats||[]).map(function(t){return '<div class="card"><div style="font-weight:600">'+t[0]+'</div><div class="muted" style="margin-top:4px">'+t[1]+'</div><div class="evidence" style="margin-top:4px">- '+t[2]+'</div></div>'}).join('');
    var dg=(c.doing||[]).map(function(t){return '<div class="card"><div style="font-weight:600">🛠️ '+t[0]+'</div><div class="muted" style="margin-top:4px">'+t[1]+'</div></div>'}).join('');
    var hp=(c.hope||[]).map(function(x){return '<div class="card" style="border-color:var(--forest)"><div style="color:var(--forest);font-weight:600">🌱 '+x[0]+'</div><div class="muted" style="margin-top:4px">'+x[1]+'</div></div>'}).join('');
    h=(th?'<h2 class="sec" style="margin-top:4px">The challenge</h2>'+th:'')+
      (dg?'<h2 class="sec">What\'s being done</h2>'+dg:'')+
      (hp?'<h2 class="sec">Reasons for hope</h2>'+hp:'');
    h=h||emptyMsg('Details are being added.');
  }
  else if(i===3){h=(c.acts||[]).map(function(sl){var a=getAct(sl);return a?actionCardHtml(sl,a):''}).join('');}
  else{h=(c.orgs||[]).map(function(o){return '<a class="lesson" style="display:block;text-decoration:none;color:var(--tx)" href="'+o[1]+'" target="_blank" rel="noopener"><b>'+o[0]+'</b> <span class="evidence">↗ visit</span></a>'}).join('')||emptyMsg('Organizations are being added.');}
  b.innerHTML=h;
  if(i===0)fillWikiOverview(c);
  else if(i===1)fillSpeciesList(c);
}
function openAction(slug){
  var a=getAct(slug);
  var h='<div class="card"><h2 style="margin:0 0 8px">'+esc(a.t)+'</h2>'+pips(a.diff)+
    ' <span class="chip" style="cursor:default">'+a.min+' min</span> <span class="chip" style="cursor:default">'+a.cost+'</span>'+(state.kid&&!isKidOk(slug)?'<span class="chip" style="cursor:default;background:var(--terra);color:#4a2c10;border-color:transparent">👨‍👧 With a grown-up</span>':'')+
    '<h2 class="sec">Why it matters</h2><p>'+esc(simpleText(a.why,a.why_simple))+'</p>'+
    '<h2 class="sec">Estimated impact</h2><p class="muted">'+esc(a.imp)+'</p>'+
    '<h2 class="sec">Steps</h2><ol class="steps">'+a.steps.map(function(s){return '<li>'+esc(s)+'</li>'}).join('')+'</ol>'+
    '<h2 class="sec">Evidence</h2><div class="muted">'+a.ev.map(esc).join(', ')+'</div>'+
    '<button class="btn'+(state.done[slug]?' done':'')+'" onclick="doAction(\''+slug+'\');closeSheet()">'+(state.done[slug]?'✓ Done - do again':'I did this')+'</button>'+
    (Object.keys(state.done).length===0?'<div class="muted" style="text-align:center;margin-top:8px;font-size:12px">Your impact is yours - log what you really did 🌱</div>':'')+'</div>';
  openSheet(h);
}
function openCourse(slug){
  var c=COURSES.filter(function(x){return x.slug===slug})[0];
  var h='<h2 style="margin:0 0 10px">'+c.t+'</h2><p class="muted">'+c.d+'</p>'+
    c.lessons.map(function(l,i){var done=state.lessons[slug+i];return '<div class="lesson" onclick="openLesson(\''+slug+'\','+i+')"><b>'+(done?'✅ ':'')+l.t+'</b><div class="muted">'+l.min+' min · tap to start</div></div>'}).join('');
  openSheet(h);
}
function openLesson(slug,i){
  var c=COURSES.filter(function(x){return x.slug===slug})[0];var l=c.lessons[i];
  var quiz=(l.quiz&&l.quiz[0])||{q:l.q,opts:l.opts,a:l.a};
  var h='<div class="card"><h2 style="margin:0 0 8px">'+l.t+'</h2>';
  if(l.body||l.body_simple){
    if(l.body_simple)h+=simpleChip("'lesson','"+slug+"',"+i);
    h+='<p style="line-height:1.65">'+simpleText(l.body,l.body_simple)+'</p>';
  }
  h+='<h2 class="sec">Quick check</h2><p style="font-weight:600">'+quiz.q+'</p><div>'+
    quiz.opts.map(function(o,oi){return '<div class="qopt" onclick="answer(\''+slug+'\','+i+','+oi+',this)">'+o+'</div>'}).join('')+'</div><div id="qres"></div></div>';
  openSheet(h);
}
function answer(slug,i,oi,el){
  var c=COURSES.filter(function(x){return x.slug===slug})[0];var l=c.lessons[i];
  var ans=(l.quiz&&l.quiz[0])?l.quiz[0].a:l.a;
  var opts=el.parentNode.children;for(var k=0;k<opts.length;k++)opts[k].onclick=null;
  if(oi===ans){el.className='qopt right';document.getElementById('qres').innerHTML='<p style="color:var(--forest)">✓ Correct! +20 XP</p><button class="btn" onclick="finishLesson(\''+slug+'\','+i+')">Continue</button>';}
  else{el.className='qopt wrong';opts[ans].className='qopt right';document.getElementById('qres').innerHTML='<p class="muted">The highlighted answer is right.</p><button class="btn" onclick="finishLesson(\''+slug+'\','+i+')">Continue</button>';}
}
function finishLesson(slug,i){
  if(!state.lessons[slug+i]){state.lessons[slug+i]=true;state.xp+=20;logToday();touchStreak();bumpMissions('lesson','');}
  var c=COURSES.filter(function(x){return x.slug===slug})[0];
  var all=c.lessons.every(function(l,idx){return state.lessons[slug+idx]});
  checkBadges();save();syncTop();
  if(all){state.badges[c.badge]=c.t+' course';save();offerShare('Course complete! '+c.badge,'You finished “'+c.t+'”. Knowledge is the first action.');}
  else{toast('+20 XP · Lesson done');openCourse(slug);}
}

/* ---- planting ceremony: a new user's first fifteen seconds ---- */
var _cerEl=null,_cerTimer=null,_cerStart=0;
function ceremonyHtml(){
  return '<div style="max-width:340px;margin:0 auto;text-align:center"><div class="cseed" id="cseed" aria-hidden="true">🌰</div><div class="soil"></div>'+
  '<h2>Every grove starts with one seed.</h2><p>Plant yours.</p>'+
  '<button class="btn holdbtn" id="cerbtn" aria-label="Hold to plant your seed" oncontextmenu="return false" onpointerdown="cerHold()" onpointerup="cerCancel()" onpointerleave="cerCancel()"><span class="fill" id="cerfill"></span><span style="position:relative">Hold to plant your seed</span></button>'+
  '<div><button class="skip" onclick="cerFinish()">skip</button></div></div>';
}
function showCeremony(){
  _cerEl=document.createElement('div');_cerEl.id='ceremony';_cerEl.className='ob';
  _cerEl.innerHTML=ceremonyHtml();document.body.appendChild(_cerEl);
}
function cerHold(){
  cerCancel();_cerStart=Date.now();
  _cerTimer=setInterval(function(){
    var pct=Math.min(100,(Date.now()-_cerStart)/1500*100);
    var f=document.getElementById('cerfill');if(f)f.style.width=pct+'%';
    var sd=document.getElementById('cseed');if(sd)sd.style.transform='translateY('+(pct*0.28)+'px) scale('+(1-pct*0.004)+')';
    if(pct>=100){cerCancel();cerGrow();}
  },50);
}
function cerCancel(){if(_cerTimer){clearInterval(_cerTimer);_cerTimer=null;}var f=document.getElementById('cerfill');if(f)f.style.width='0%';var sd=document.getElementById('cseed');if(sd)sd.style.transform='';}
function cerGrow(){
  state.onboarded=true;save();celebrateBurst();
  if(_cerEl)_cerEl.innerHTML='<div style="max-width:340px;margin:0 auto;text-align:center"><div class="cseed" style="animation:pop .5s ease" aria-hidden="true">🌱</div><div class="soil"></div>'+
  '<h2>Day one. Your grove is alive.</h2><p>Your first action is waiting.</p>'+
  '<button class="btn" style="max-width:320px;margin-left:auto;margin-right:auto" onclick="cerFinish()">Begin →</button></div>';
}
function cerFinish(){
  if(!state.onboarded){state.onboarded=true;save();}
  if(_cerEl&&_cerEl.parentNode)_cerEl.parentNode.removeChild(_cerEl);_cerEl=null;
  render();toast('🌱 Welcome to Hopeling');
}
/* nav / theme / onboarding / reminders / install */
function hpt(ms){try{if(navigator.vibrate)navigator.vibrate(ms||8)}catch(e){}}
var GRAT={'oceans':'🐟','coral-reefs':'🐠','sea-turtles':'🐢','whales':'🐋','sharks':'🦈','dolphins':'🐬','penguins':'🐧','birds':'🐦','bees':'🐝','butterflies':'🦋','forests':'🦋','freshwater':'🐸','elephants':'🐘','gorillas':'🦍','orangutans':'🦧','tigers':'🐅','pandas':'🐼','rhinos':'🦏','wolves':'🐺','foxes':'🦊','dogs':'🐕','cats':'🐈','farm-animals':'🐄','polar-bears':'🐻‍❄️','lions':'🦁'};
function gratFly(slug){
  try{
    if(typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    var cats=ACT_CATS[slug]||[];var e=GRAT[cats[0]]||'🍃';
    var sp=document.createElement('span');sp.className='gratfly';sp.textContent=e;
    sp.style.top=(16+Math.random()*30)+'%';sp.setAttribute('aria-hidden','true');
    document.body.appendChild(sp);hpt(15);
    setTimeout(function(){if(sp.parentNode)sp.parentNode.removeChild(sp);},2600);
  }catch(err){}
}
function groveGlow(){
  try{
    if(typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    var h=document.createElement('div');h.className='glowup';h.setAttribute('aria-hidden','true');
    for(var i=0;i<12;i++){var d=document.createElement('i');d.style.left=(6+Math.random()*88)+'%';d.style.animationDelay=(Math.random()*0.9)+'s';h.appendChild(d);}
    document.body.appendChild(h);hpt(25);
    setTimeout(function(){if(h.parentNode)h.parentNode.removeChild(h);},3800);
  }catch(err){}
}
function maybeVisitor(){
  try{
    if(tab!=='home')return;
    if(LS.get('lastVis','')===today())return;
    if(Math.random()>0.06)return;
    LS.set('lastVis',today());
    var hh=new Date().getHours();
    var pool=(hh>=17||hh<7)?['🦊','🦉','🦔']:['🦌','🐿️','🐇'];
    var e=pool[Math.floor(Math.random()*pool.length)];
    setTimeout(function(){
      var sp=document.createElement('span');sp.className='visitor';sp.textContent=e;sp.setAttribute('aria-hidden','true');
      document.body.appendChild(sp);
      setTimeout(function(){if(sp.parentNode)sp.parentNode.removeChild(sp);},7400);
    },2200);
  }catch(err){}
}
var ICO={
 home:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 11.2 12 4.5l7.5 6.7"/><path d="M6.3 10v8.6c0 .6.4 1 1 1h3V14h3.4v5.6h3c.6 0 1-.4 1-1V10"/></svg>',
 explore:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8.4"/><path d="M15 9l-2 4.2L8.8 15l2-4.2L15 9z" fill="currentColor" stroke="none"/></svg>',
 act:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M13 3.5 5.5 13.5h5l-1 7 7.5-10h-5l1-7z"/></svg>',
 learn:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 6.6C10.2 4.9 7.2 4.6 4.8 5.3v13c2.4-.7 5.4-.4 7.2 1.3 1.8-1.7 4.8-2 7.2-1.3v-13c-2.4-.7-5.4-.4-7.2 1.3z"/><path d="M12 6.6v13"/></svg>',
 me:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8.2" r="3.6"/><path d="M5.6 19.6c1-3.6 3.4-5.4 6.4-5.4s5.4 1.8 6.4 5.4"/></svg>',
 search:'<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"><circle cx="11" cy="11" r="6.4"/><path d="m15.9 15.9 4.1 4.1"/></svg>',
 back:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 5.5 8 12l6.5 6.5"/></svg>',
 sun:'<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M18.4 5.6 17 7M7 17l-1.4 1.4"/></svg>',
 moon:'<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8.3 8.3 0 1 1 9.5 4 6.6 6.6 0 0 0 20 14.5z"/></svg>'
};
function go(t){hpt(6);tab=t;render();closeSheet();window.scrollTo(0,0);buildNav();try{if(window.goatcounter&&window.goatcounter.count)window.goatcounter.count({path:'tab-'+t,event:true});}catch(e){}}
function buildNav(){
  var tabs=[['home','🏠','Home'],['explore','🧭','Explore'],['act','⚡','Act'],['learn','🎓','Learn'],['me','👤','Me']];
  document.getElementById('nav').innerHTML=tabs.map(function(t){return '<button class="'+(tab===t[0]?'on':'')+'" onclick="go(\''+t[0]+'\')" aria-label="'+t[2]+'"><span class="i" aria-hidden="true">'+t[1]+'</span>'+t[2]+'</button>'}).join('');
}
function applyKid(){document.documentElement.setAttribute('data-kid',state.kid?'1':'0');}
function toggleKid(){state.kid=!state.kid;save();applyKid();render();toast(state.kid?'🧒 Kid mode on 🌈':'Kid mode off');}
function applyTheme(){var d=state.theme==='dark'||(state.theme===null&&window.matchMedia&&window.matchMedia('(prefers-color-scheme:dark)').matches);
  document.documentElement.setAttribute('data-theme',d?'dark':'light');document.getElementById('themeBtn').innerHTML=d?ICO.sun:ICO.moon;}
function toggleTheme(){var cur=document.documentElement.getAttribute('data-theme');state.theme=cur==='dark'?'light':'dark';save();applyTheme();render();}
function resetAll(){if(confirm('Reset all your progress?')){state.xp=0;state.streak=0;state.last=null;state.done={};state.lessons={};state.badges={};state.totals={};state.log={};save();toast('Fresh start 🌱');render();}}
function toggleRemind(){
  if(!state.remind){
    if('Notification'in window){Notification.requestPermission().then(function(p){state.remind=(p==='granted');save();render();if(state.remind)toast('Reminders on 🔔');});return;}
    toast('Notifications not supported here');
  } else {state.remind=false;save();render();}
}
function maybeRemind(){
  if(!state.remind||!('Notification'in window)||Notification.permission!=='granted')return;
  if(state.last===today())return; // already acted
  if(state.lastRemind===today())return;
  state.lastRemind=today();save();
  try{new Notification('🌿 Your daily action is waiting',{body:'One small action keeps your streak alive.',icon:'icon-192.png'});}catch(e){}
}

var installEvt=null;
function isStandalone(){return window.matchMedia&&window.matchMedia('(display-mode: standalone)').matches||window.navigator.standalone===true;}
window.addEventListener('beforeinstallprompt',function(e){e.preventDefault();installEvt=e;if(state.onboarded)render();});
function doInstall(){if(installEvt){installEvt.prompt();installEvt=null;}else{toast('On iPhone: Share → Add to Home Screen');}}

/* ---- custom actions ---- */
function openAddAction(){
  var metrics=[['generic','Just count it'],['plastic_kg','Plastic avoided (kg)'],['trees','Trees planted'],['money','Money donated ($)'],['carbon_kg','CO₂ saved (kg)'],['animals','Animals helped'],['hours','Volunteer hours']];
  var h='<div class="card"><h2 style="margin:0 0 10px">Add your own action</h2>'+
    '<div class="field"><label for="ca_t">What did you do?</label><input id="ca_t" placeholder="e.g. Cleaned a local pond"/></div>'+
    '<div class="field"><label for="ca_d">Difficulty</label><select id="ca_d"><option value="1">Easy</option><option value="2">Medium</option><option value="3">High impact</option></select></div>'+
    '<div class="field"><label for="ca_m">Impact type</label><select id="ca_m">'+metrics.map(function(m){return '<option value="'+m[0]+'">'+m[1]+'</option>'}).join('')+'</select></div>'+
    '<div class="field"><label for="ca_v">Amount (optional)</label><input id="ca_v" type="number" inputmode="decimal" placeholder="e.g. 3"/></div>'+
    '<button class="btn" onclick="saveCustomAction()">Add action</button></div>';
  openSheet(h);
}
function saveCustomAction(){
  var t=(document.getElementById('ca_t').value||'').trim();if(!t){toast('Give it a name');return;}
  var slug='custom-'+Date.now();
  state.customActions[slug]={t:t,why:'Your own action.',imp:'Logged by you.',diff:parseInt(document.getElementById('ca_d').value)||1,mod:'home',cost:'Free',min:5,metric:document.getElementById('ca_m').value,val:parseFloat(document.getElementById('ca_v').value)||0,ev:['You'],steps:['You defined this action'],custom:true};
  save();closeSheet();go('act');toast('Added ✓ - tap "Do it" to log it');
}
/* ---- manual impact logging ---- */
function openLogImpact(){
  var metrics=[['plastic_kg','Plastic avoided (kg)'],['trees','Trees planted'],['money','Money donated ($)'],['carbon_kg','CO₂ saved (kg)'],['animals','Animals helped'],['hours','Volunteer hours']];
  var h='<div class="card"><h2 style="margin:0 0 10px">Log real impact</h2>'+
    '<div class="field"><label for="li_m">What?</label><select id="li_m">'+metrics.map(function(m){return '<option value="'+m[0]+'">'+m[1]+'</option>'}).join('')+'</select></div>'+
    '<div class="field"><label for="li_v">Amount</label><input id="li_v" type="number" inputmode="decimal" placeholder="e.g. 2"/></div>'+
    '<button class="btn" onclick="saveLogImpact()">Log it</button></div>';
  openSheet(h);
}
function saveLogImpact(){
  var m=document.getElementById('li_m').value,v=parseFloat(document.getElementById('li_v').value);
  if(!v||v<=0){toast('Enter an amount');return;}
  state.totals[m]=(state.totals[m]||0)+v;state.xp+=10;logToday();touchStreak();bumpMissions('action','');bumpEvent('');checkBadges();save();syncTop();closeSheet();go('me');toast('Logged +10 XP 🌱');
}
/* ---- impact calculator ---- */
function impactPhrase(metric,v){
  if(metric==='carbon_kg')return['🌍 '+round(v)+' kg CO₂e saved','≈ '+Math.round(v/0.17).toLocaleString()+' km of car driving avoided'];
  if(metric==='plastic_kg')return['♻️ '+round(v)+' kg plastic avoided','≈ '+Math.round(v*125).toLocaleString()+' plastic bags never used'];
  if(metric==='trees')return['🌳 '+Math.round(v)+' native trees','absorbing ≈ '+Math.round(v*21).toLocaleString()+' kg CO₂ every year after'];
  if(metric==='money')return['💚 $'+Math.round(v).toLocaleString()+' donated','funding ranger patrols, habitat and rescues'];
  if(metric==='animals')return['🐾 ≈ '+Math.round(v).toLocaleString()+' animals helped','directly, because of you'];
  return['⭐ '+Math.round(v).toLocaleString()+' actions','a steady drumbeat of hope'];
}
function calcImpact(){
  var sel=document.getElementById('ic_a'),fr=document.getElementById('ic_f'),out=document.getElementById('ic_out');
  if(!sel||!fr||!out)return;
  var a=getAct(sel.value);var n=parseInt(fr.value)||52;
  if(!a)return;
  var ph=impactPhrase(a.metric,(a.val||1)*n);
  out.innerHTML='<div class="grad g-forest" style="margin-top:6px"><div class="lbl">IN ONE YEAR</div>'+
    '<div style="font-size:22px;font-weight:700;margin-top:6px">'+ph[0]+'</div>'+
    '<div style="opacity:.9;margin-top:4px">'+ph[1]+'</div>'+
    (a.min?'<div class="lbl" style="margin-top:8px">'+(Math.round(a.min*n/60*10)/10)+' hours of your year</div>':'')+'</div>';
}
function paceHtml(){
  var days=Object.keys(state.log).filter(function(k){return state.log[k]>0}).sort();
  if(days.length<3)return '<div class="card"><div style="font-weight:600">📈 Your pace</div><div class="muted" style="margin-top:4px">Log actions on a few more days and this will project your whole year.</div></div>';
  var span=Math.max(1,daysBetween(days[0],today())+1),total=0;
  days.forEach(function(k){total+=state.log[k]});
  var perYear=Math.round(total/span*365);
  var h='<div class="card"><div style="font-weight:600">📈 Your pace</div>'+
    '<div class="muted" style="margin-top:4px">'+total+' action'+(total===1?'':'s')+' in '+span+' day'+(span===1?'':'s')+'. If you keep this up:</div>'+
    '<div style="font-size:20px;font-weight:700;color:var(--forest);margin-top:6px">'+perYear.toLocaleString()+' actions a year 🌱</div>';
  var mets=[['plastic_kg','♻️ Plastic avoided','kg'],['carbon_kg','🌍 CO₂e saved','kg'],['trees','🌳 Trees',''],['money','💚 Donated','$'],['animals','🐾 Animals helped','']];
  mets.forEach(function(m){var v=state.totals[m[0]]||0;if(!v)return;
    var vy=Math.round(v/span*365*10)/10;
    h+='<div class="muted" style="margin-top:3px">'+m[1]+': ~'+(m[2]==='$'?'$'+vy.toLocaleString():vy.toLocaleString()+' '+m[2]).trim()+' / year</div>';});
  return h+'</div>';
}
function openCalc(){
  var opts=allActSlugs().map(function(sl){var a=getAct(sl);return '<option value="'+sl+'">'+esc(a.t)+'</option>'}).join('');
  var h='<div class="card"><h2 style="margin:0 0 6px">🔮 Impact calculator</h2>'+
    '<p class="muted" style="margin-top:0">Small actions look small - until you give them a year.</p>'+
    '<div class="field"><label for="ic_a">One habit</label><select id="ic_a">'+opts+'</select></div>'+
    '<div class="field"><label for="ic_f">How often</label><select id="ic_f">'+
      '<option value="365">Every day</option><option value="156">3× a week</option>'+
      '<option value="52" selected>Once a week</option><option value="12">Once a month</option></select></div>'+
    '<div id="ic_out"></div></div>'+paceHtml();
  openSheet(h);
  var a=document.getElementById('ic_a'),f=document.getElementById('ic_f');
  if(a)a.onchange=calcImpact; if(f)f.onchange=calcImpact;
  calcImpact();
}
/* ---- search ---- */
function openPlate(){
  var f=FACTS[dailyIndex(FACTS.length,'f')];
  var h='<div class="card" style="padding:0;overflow:hidden">'+
    (_heroUrl?'<div style="height:38vh;background:url(\''+_heroUrl+'\') center/cover" aria-hidden="true"></div>':'<div style="height:22vh;background:linear-gradient(120deg,#2E6B4F,#0B3D4C)"></div>')+
    '<div style="padding:22px"><div class="lbl" style="color:var(--tx2)">TODAY\'S FACT</div>'+
    '<p style="font-family:var(--serif);font-style:italic;font-size:24px;line-height:1.45;margin:10px 0 6px">'+esc(simpleText(f[0],f[3]))+'</p>'+
    '<div class="muted">- '+esc(f[1])+'</div></div></div>'+
    '<button class="btn" onclick="sharePlate()">📤 Share this as a poster</button>';
  openSheet(h);
}
function sharePlate(){
  var f=FACTS[dailyIndex(FACTS.length,'f')];
  try{
    var cv=document.createElement('canvas');
    if(typeof cv.getContext!=='function'){toast('Not supported here');return;}
    cv.width=1080;cv.height=1350;var x=cv.getContext('2d');
    function paint(img){
      if(img){var r=Math.max(1080/img.width,1350/img.height);var w=img.width*r,hh=img.height*r;x.drawImage(img,(1080-w)/2,(1350-hh)/2,w,hh);x.fillStyle='rgba(8,20,14,.55)';x.fillRect(0,0,1080,1350);}
      else{var g=x.createLinearGradient(0,0,1080,1350);g.addColorStop(0,'#2E6B4F');g.addColorStop(1,'#0B3D4C');x.fillStyle=g;x.fillRect(0,0,1080,1350);}
      x.fillStyle='rgba(255,255,255,.85)';x.font='600 34px -apple-system,Segoe UI,Arial';x.textAlign='center';
      x.fillText("TODAY'S FACT",540,170);
      x.font='italic 58px Georgia,serif';x.fillStyle='#fff';
      var words=(simpleText(f[0],f[3])||'').split(' '),line='',lines=[];
      for(var i2=0;i2<words.length;i2++){var t2=line+words[i2]+' ';if(x.measureText(t2).width>880&&line){lines.push(line);line=words[i2]+' ';}else line=t2;}
      lines.push(line);
      var y0=560-lines.length*40;
      lines.forEach(function(l,li){x.fillText(l.trim(),540,y0+li*82);});
      x.font='400 36px Georgia,serif';x.fillStyle='#B2F1CC';x.fillText('- '+f[1],540,y0+lines.length*82+40);
      x.font='600 40px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.9)';x.fillText('🌿 hopeling.app',540,1240);
      cv.toBlob(function(blob){
        if(!blob){toast('Could not create image');return;}
        var file=new File([blob],'hopeling-fact.png',{type:'image/png'});
        if(navigator.canShare&&navigator.canShare({files:[file]})){navigator.share({files:[file],title:'Wild fact',text:'From Hopeling 🌿'}).catch(function(){});}
        else{var url=URL.createObjectURL(blob);var a=document.createElement('a');a.href=url;a.download='hopeling-fact.png';document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(url)},1000);toast('Poster saved 📤');}
      },'image/png');
    }
    if(_heroUrl){var im=new Image();im.crossOrigin='anonymous';im.onload=function(){try{paint(im);}catch(e2){paint(null);}};im.onerror=function(){paint(null);};im.src=_heroUrl;}
    else paint(null);
  }catch(e){toast('Could not create image');}
}
function openSearch(){
  openSheet('<div class="card"><input id="sq" placeholder="Search species, actions, courses…" oninput="doSearch()"/></div><div id="sres"></div>');
  setTimeout(function(){var e=document.getElementById('sq');if(e)e.focus();},60);doSearch();
}
function doSearch(){
  var e=document.getElementById('sq');if(!e)return;var q=(e.value||'').toLowerCase().trim();var r=document.getElementById('sres');
  if(!q){r.innerHTML='<div class="muted" style="padding:12px">Try "plastic", "turtles", "palm oil"…</div>';return;}
  var out='';
  var cats=CATS.filter(function(c){return (c.name+' '+c.sum).toLowerCase().indexOf(q)>=0;});
  if(cats.length)out+='<h2 class="sec">Species & ecosystems</h2>'+cats.map(function(c){return '<div class="lesson" onclick="openCat(\''+c.slug+'\')">'+c.emo+' '+c.name+'</div>'}).join('');
  var acts=allActSlugs().filter(function(sl){var a=getAct(sl);return (a.t+' '+(a.why||'')).toLowerCase().indexOf(q)>=0;});
  if(acts.length)out+='<h2 class="sec">Actions</h2>'+acts.map(function(sl){var a=getAct(sl);return '<div class="lesson" onclick="openAction(\''+sl+'\')">⚡ '+esc(a.t)+'</div>'}).join('');
  var courses=COURSES.filter(function(c){return c.t.toLowerCase().indexOf(q)>=0;});
  if(courses.length)out+='<h2 class="sec">Courses</h2>'+courses.map(function(c){return '<div class="lesson" onclick="openCourse(\''+c.slug+'\')">🎓 '+c.t+'</div>'}).join('');
  r.innerHTML=out||'<div class="muted" style="padding:12px">No matches for "'+esc(q)+'".</div>';
}
/* ---- live enrichment: Wikipedia + GBIF, cached in localStorage for offline ---- */
function esc(x){return String(x).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}
var CAT_WIKI={'sea-turtles':'Sea turtle','whales':'Whale','sharks':'Shark','dolphins':'Dolphin','elephants':'Elephant','gorillas':'Gorilla','orangutans':'Orangutan','lions':'Lion','tigers':'Tiger','pandas':'Giant panda','rhinos':'Rhinoceros','wolves':'Wolf','foxes':'Fox','penguins':'Penguin','polar-bears':'Polar bear','dogs':'Dog','cats':'Cat','birds':'Bird','bees':'Pollinator','oceans':'Ocean','coral-reefs':'Coral reef','forests':'Forest','freshwater':'Freshwater ecosystem','farm-animals':'Livestock'};
var SPECIES={
 'sea-turtles':['Loggerhead sea turtle','Green sea turtle','Leatherback sea turtle','Hawksbill sea turtle',"Kemp's ridley sea turtle"],
 'whales':['Blue whale','Humpback whale','Sperm whale','North Atlantic right whale','Beluga whale'],
 'sharks':['Great white shark','Whale shark','Great hammerhead','Basking shark','Shortfin mako shark'],
 'dolphins':['Common bottlenose dolphin','Orca','Amazon river dolphin','Vaquita','Spinner dolphin'],
 'elephants':['African bush elephant','African forest elephant','Asian elephant'],
 'gorillas':['Mountain gorilla','Western lowland gorilla','Eastern gorilla','Cross River gorilla'],
 'orangutans':['Bornean orangutan','Sumatran orangutan','Tapanuli orangutan'],
 'tigers':['Bengal tiger','Siberian tiger','Sumatran tiger','Malayan tiger'],
 'pandas':['Giant panda','Red panda'],
 'rhinos':['White rhinoceros','Black rhinoceros','Indian rhinoceros','Javan rhinoceros','Sumatran rhinoceros'],
 'wolves':['Gray wolf','Red wolf','Ethiopian wolf','Maned wolf'],
 'foxes':['Red fox','Arctic fox','Fennec fox',"Darwin's fox"],
 'polar-bears':['Polar bear','Ringed seal','Arctic fox','Walrus','Narwhal','Beluga whale','Snowy owl'],
 'penguins':['Emperor penguin','King penguin','African penguin','Galapagos penguin','Little penguin'],
 'dogs':['Dog','Dingo','African wild dog'],
 'cats':['Cat','European wildcat','Sand cat'],
 'birds':['Bald eagle','Atlantic puffin','California condor','Snowy owl','Kiwi'],
 'bees':['Western honey bee','Bumblebee','Monarch butterfly','Mason bee','Hoverfly'],
 'oceans':['Sea otter','West Indian manatee','Giant Pacific octopus','Krill'],
 'coral-reefs':['Staghorn coral','Clownfish','Parrotfish','Giant clam'],
 'forests':['Jaguar','Three-toed sloth','Harpy eagle','Okapi'],
 'freshwater':['Axolotl','Platypus','North American river otter','Atlantic salmon','Hellbender'],
 'farm-animals':['Chicken','Domestic pig','Cattle','Sheep','Goat']
};
function catSpecies(c){return (c.species&&c.species.length)?c.species:(SPECIES[c.slug]||[]);}
var WIKI_TTL=2592e6; /* 30 days */
function wikiGet(title,cb){
  var key='wiki_'+title,c=LS.get(key,null);
  if(c&&c.d&&(Date.now()-c.ts)<WIKI_TTL){cb(c.d);return;}
  fetch('https://en.wikipedia.org/api/rest_v1/page/summary/'+encodeURIComponent(title.split(' ').join('_')))
    .then(function(r){return r.ok?r.json():null})
    .then(function(d){
      if(d&&d.extract){
        var slim={t:d.title,x:d.extract,desc:d.description||'',img:(d.thumbnail&&d.thumbnail.source)||null,big:(d.originalimage&&d.originalimage.source)||null,url:(d.content_urls&&d.content_urls.desktop&&d.content_urls.desktop.page)||null};
        LS.set(key,{ts:Date.now(),d:slim});cb(slim);
      } else cb((c&&c.d)||null);
    }).catch(function(){cb((c&&c.d)||null);});
}
function gbifGet(name,cb){
  var key='gbif_'+name,c=LS.get(key,null);
  if(c&&c.d&&(Date.now()-c.ts)<WIKI_TTL){cb(c.d);return;}
  fetch('https://api.gbif.org/v1/species/match?name='+encodeURIComponent(name))
    .then(function(r){return r.ok?r.json():null})
    .then(function(m){
      if(!m||!m.usageKey){cb((c&&c.d)||null);return;}
      fetch('https://api.gbif.org/v1/occurrence/search?taxonKey='+m.usageKey+'&limit=0')
        .then(function(r){return r.ok?r.json():null})
        .then(function(o){var slim={sci:m.scientificName||'',n:(o&&o.count)||0,key:m.usageKey};LS.set(key,{ts:Date.now(),d:slim});cb(slim);})
        .catch(function(){cb({sci:m.scientificName||'',n:0,key:m.usageKey});});
    }).catch(function(){cb((c&&c.d)||null);});
}
function speciesListHtml(c){
  var sp=catSpecies(c);
  if(!sp.length)return emptyMsg('Species profiles are being added.');
  return sp.map(function(n,i){
    return '<div class="lesson" style="display:flex;gap:12px;align-items:center" onclick="openSpecies(\''+encodeURIComponent(n)+'\',\''+c.slug+'\')">'+
      '<div id="spimg'+i+'" style="width:56px;height:56px;border-radius:12px;background:var(--line);flex:none;background-size:cover;background-position:center" aria-hidden="true"></div>'+
      '<div style="min-width:0"><b>'+esc(n)+'</b><div class="muted" id="spdesc'+i+'">Loading…</div></div></div>';
  }).join('')+'<div class="muted" style="margin-top:6px;font-size:11px">Photos & summaries: Wikipedia (CC BY-SA), loaded live and saved for offline. Records: GBIF.</div>';
}
function fillSpeciesList(c){
  catSpecies(c).forEach(function(n,i){
    wikiGet(n,function(d){
      var de=document.getElementById('spdesc'+i),im=document.getElementById('spimg'+i);
      if(!de||!im)return;
      if(d){de.textContent=d.desc||(d.x?d.x.slice(0,70)+'…':'');if(d.img)im.style.backgroundImage='url("'+d.img+'")';}
      else de.textContent='Offline - open once online to load.';
    });
  });
}
function fillWikiOverview(c){
  wikiGet(c.wiki||CAT_WIKI[c.slug]||c.name,function(d){
    var e=document.getElementById('wikiOv');if(!e||!d)return;
    e.innerHTML='<h2 class="sec">About</h2><div class="card">'+
      (d.img?'<div style="height:140px;border-radius:12px;background:url(\''+d.img+'\') center/cover" aria-hidden="true"></div>':'')+
      '<p style="line-height:1.6;margin-bottom:6px">'+esc(d.x)+'</p>'+
      (d.url?'<a class="evidence" href="'+d.url+'" target="_blank" rel="noopener">Wikipedia (CC BY-SA) ↗</a>':'');
  });
}
function openSpecies(enc,slug){
  var n=decodeURIComponent(enc);var c=CATS.filter(function(x){return x.slug===slug})[0];
  var h='<button class="chip" onclick="openCat(\''+slug+'\')">← '+esc(c?c.name:'Back')+'</button>'+
    '<div class="card" style="margin-top:10px">'+
    '<div id="spBig" style="height:180px;border-radius:14px;background:var(--line);background-size:cover;background-position:center" aria-hidden="true"></div>'+
    '<h2 style="margin:12px 0 2px">'+esc(n)+'</h2><div class="muted" id="spTag"></div>'+
    '<p id="spX" style="line-height:1.65">Loading…</p>'+
    '<div id="spGbif" class="muted"></div><div id="spLinks" style="margin-top:8px"></div>'+
    '<div class="muted" style="margin-top:10px;font-size:11px">Text & photo: Wikipedia (CC BY-SA). Sighting records: GBIF.</div></div>';
  openSheet(h);
  wikiGet(n,function(d){
    var x=document.getElementById('spX');if(!x)return;
    if(d){
      x.textContent=d.x;
      var tg=document.getElementById('spTag');if(tg)tg.textContent=d.desc||'';
      var bg=document.getElementById('spBig');if(bg&&(d.big||d.img))bg.style.backgroundImage='url("'+(d.big||d.img)+'")';
      var lk=document.getElementById('spLinks');if(lk&&d.url)lk.innerHTML='<a class="evidence" href="'+d.url+'" target="_blank" rel="noopener">Read more on Wikipedia ↗</a>';
    } else x.textContent="You're offline. Open this once online and it will be saved for offline reading.";
  });
  gbifGet(n,function(g){
    var e=document.getElementById('spGbif');if(!e||!g||!g.sci)return;
    e.innerHTML='🔬 <i>'+esc(g.sci)+'</i>'+(g.n?' · '+g.n.toLocaleString()+' recorded sightings (GBIF)':'');
  });
}
