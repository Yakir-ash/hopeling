/* Hopeling - app.js (split from Hopeling.html, shared global scope, load order matters) */
/* ---- backup / restore ---- */
function exportProgress(){
  var data={_app:'Hopeling',_exported:new Date().toISOString()};
  SAVE_KEYS.forEach(function(k){data[k]=state[k];});
  var blob=new Blob([JSON.stringify(data,null,2)],{type:'application/json'});
  var url=URL.createObjectURL(blob);var a=document.createElement('a');a.href=url;a.download='hopeling-backup-'+today()+'.json';document.body.appendChild(a);a.click();a.remove();
  setTimeout(function(){URL.revokeObjectURL(url)},1000);state.lastBackup=today();save();toast('Backup saved 💾');if(tab==='home')render();
}
function importProgress(ev){
  var f=ev.target.files[0];if(!f)return;var rd=new FileReader();
  rd.onload=function(){try{var d=JSON.parse(rd.result);
    if(d._app!=='Hopeling'&&!confirm('This may not be a Hopeling backup. Import anyway?'))return;
    if(!confirm('Restore this backup? It replaces your current progress.'))return;
    SAVE_KEYS.forEach(function(k){if(d[k]!==undefined)state[k]=d[k];});
    if(state.customActions){var ca={};Object.keys(state.customActions).forEach(function(k2){if(/^[\w-]+$/.test(k2))ca[k2]=state.customActions[k2];});state.customActions=ca;}
    state.lastBackup=today();save();applyTheme();render();toast('Progress restored ✓');
  }catch(e){toast('That file could not be read');}};
  rd.readAsText(f);ev.target.value='';
}
/* ---- spirit species quiz ---- */
var SPIRITS={
 otter:{e:'🦦',n:'Sea Otter',tag:'Playful heart, busy hands',d:'You make heavy things feel light. People recharge around you, and you learn by touching, trying and playing - work that feels like play is where you shine.',hook:'Sea otters hold whole kelp forests together by keeping urchins in check. Protect their coasts and thousands of species thrive with them.',cat:'oceans'},
 dolphin:{e:'🐬',n:'Dolphin',tag:'Quick mind, open heart',d:'Social, fast and curious - you think best out loud and mid-motion. Your energy is contagious and your circle knows they can count on you.',hook:'Dolphins are guardians of healthy seas - where they struggle, oceans are struggling. Less noise, cleaner water and safer nets keep their pods strong.',cat:'dolphins'},
 turtle:{e:'🐢',n:'Sea Turtle',tag:'Calm power, long horizons',d:'You play the long game. Steady, unhurried and quietly unstoppable, you cross oceans while others circle the harbor.',hook:'Sea turtles have crossed oceans for 100 million years - now plastic and bright beaches confuse their journeys. Every refused bag genuinely helps.',cat:'sea-turtles'},
 whale:{e:'🐋',n:'Whale',tag:'Deep currents, few words',d:'You feel things at depth and speak when it matters. People come to you for perspective - you carry the big picture where others see waves.',hook:'A single great whale stores tons of carbon and feeds entire ecosystems. Quieter, cleaner oceans let their songs carry.',cat:'whales'},
 wolf:{e:'🐺',n:'Wolf',tag:'Loyal to the pack, wild at heart',d:'You show up for your people, full stop. You are happiest working as a team toward something bigger, preferably somewhere the WiFi is weak.',hook:'Wolves returning to old ranges revived rivers and forests. Coexistence - not fear - is what their comeback needs.',cat:'wolves'},
 owl:{e:'🦉',n:'Owl',tag:'Sees what others miss',d:'You watch, you listen, you understand - then you act once, precisely. Your quiet hours are where your best thinking lives.',hook:'Owls are nature\'s pest control, but rodent poisons travel up the food chain to them. Poison-free gardens keep the night watch flying.',cat:'birds'},
 eagle:{e:'🦅',n:'Eagle',tag:'High vantage, own path',d:'Independent and far-sighted, you need altitude - literal or mental - to feel yourself. You commit rarely, and completely.',hook:'Eagles came back from the brink once before, when people banned DDT. Bold protection works - they still need clean rivers and lead-free land.',cat:'birds'},
 fox:{e:'🦊',n:'Fox',tag:'Clever, adaptable, a little mischievous',d:'You land on your feet anywhere. Streets or forests, plan A or plan F - your wit is your compass and change never scares you for long.',hook:'Foxes thrive beside us when we let them - safer roads, fewer poisons and a bit of wildness in our cities keep the trickster around.',cat:'foxes'},
 hedgehog:{e:'🦔',n:'Hedgehog',tag:'Soft heart, good boundaries',d:'Home is your superpower. You tend your patch, love your people gently, and prove that small and quiet can still change everything around it.',hook:'Hedgehogs need connected gardens - a hand-sized gap in a fence links a whole neighborhood of habitat. Small kindnesses, big range.',cat:'forests'},
 bee:{e:'🐝',n:'Bee',tag:'Purpose in every hour',d:'You turn intention into motion. Organized, generous and quietly essential - communities work because people like you keep showing up.',hook:'One in three bites of food depends on pollinators. Every pesticide-free flower patch is infrastructure for life itself.',cat:'bees'},
 butterfly:{e:'🦋',n:'Butterfly',tag:'Transformation is your language',d:'You have already been more than one person in this life, and you are not done. You chase beauty, cross-pollinate ideas, and refuse to stay in one box.',hook:'Butterflies are rebuilding their routes one wildflower at a time. Plant natives and your garden becomes a stop on a continental journey.',cat:'butterflies'},
 elephant:{e:'🐘',n:'Elephant',tag:'Deep roots, long memory',d:'You remember birthdays, promises and who needs checking on. Family - chosen or given - is your center of gravity, and your steadiness holds others up.',hook:'Elephants plant forests as they walk, spreading the seeds of a hundred tree species. Protecting their corridors protects everything on the path.',cat:'elephants'}
};
var QUIZ=[
 ['Your perfect Saturday?',[
  ['🌊 By the water - in it, on it, near it',{otter:2,dolphin:2,turtle:1,whale:1}],
  ['🌲 Deep on a forest trail',{wolf:2,owl:1,eagle:1}],
  ['🏡 Home - garden, kitchen, small projects',{hedgehog:2,bee:1,elephant:1}],
  ['🧭 Wandering somewhere new',{butterfly:2,fox:1,eagle:1}]]],
 ['When are you most alive?',[
  ['🌅 Dawn - first light, fresh start',{bee:2,eagle:1,elephant:1}],
  ['🌙 Late night, when the world goes quiet',{owl:2,fox:2}],
  ['☀️ Steady all day long',{turtle:2,elephant:1,whale:1}],
  ['⚡ In bursts - all in, then recharge',{dolphin:2,otter:2}]]],
 ['In your group of friends, you\'re...',[
  ['📅 The one who organizes everything',{bee:2,elephant:2}],
  ['😄 The spark - jokes, energy, ideas',{otter:2,dolphin:1,butterfly:1}],
  ['👂 The listener everyone trusts',{whale:2,owl:1,hedgehog:1}],
  ['🧭 Honestly? Happiest in small doses',{eagle:2,turtle:1,fox:1}]]],
 ['A hard problem lands on you. You...',[
  ['🧪 Tinker with it until it cracks',{fox:2,otter:1}],
  ['📐 Step back and plan it properly',{owl:2,elephant:1}],
  ['🤝 Rally people - together it\'s easy',{wolf:2,bee:1}],
  ['🌊 Trust your gut and dive',{dolphin:1,eagle:1,butterfly:1}]]],
 ['What do you protect most fiercely?',[
  ['👪 My people - loyalty is everything',{wolf:2,elephant:2}],
  ['🕊️ My freedom to change course',{butterfly:2,eagle:1,fox:1}],
  ['🕯️ My peace and depth',{whale:2,owl:1,hedgehog:1,turtle:1}],
  ['🎉 The joy in the room',{dolphin:2,otter:1,bee:1}]]],
 ['Your natural pace?',[
  ['🐢 Long, steady journeys',{turtle:2,whale:1,elephant:1}],
  ['🍃 Quick and light on my feet',{butterfly:2,fox:1}],
  ['🐝 Busy, but every hour has a purpose',{bee:2,wolf:1}],
  ['🌒 Still and quiet - until the moment\'s right',{owl:2,hedgehog:2}]]],
 ['Which place calls to you?',[
  ['🌊 The open ocean',{whale:2,dolphin:1,turtle:1,otter:1}],
  ['🌲 A deep, old forest',{wolf:1,owl:1,hedgehog:1}],
  ['🌸 A meadow in full bloom',{butterfly:1,bee:1,hedgehog:1}],
  ['⛰️ A mountain, sky everywhere',{eagle:2,wolf:1}]]]
];
var SPIRIT_KIN={otter:'vaquita',dolphin:'vaquita',turtle:'hawksbill',whale:'right-whale',wolf:'snow-leopard',owl:'kakapo',eagle:'kakapo',fox:'saola',hedgehog:'axolotl',bee:'monarch',butterfly:'monarch',elephant:'black-rhino'};
var _quizAns=null;
function openQuiz(){_quizAns=[];renderQuizQ();}
function renderQuizQ(){
  var i=_quizAns.length;
  if(i>=QUIZ.length){finishQuiz();return;}
  var q=QUIZ[i];
  var h='<div class="card"><div class="lbl" style="color:var(--tx2)">SPIRIT SPECIES QUIZ · '+(i+1)+'/'+QUIZ.length+'</div>'+
    '<h2 style="margin:8px 0 14px">'+q[0]+'</h2>'+
    q[1].map(function(o,oi){return '<button class="qopt" style="display:block;width:100%;text-align:left;background:none;font-family:inherit;font-size:14px;color:var(--tx)" onclick="quizPick('+oi+')">'+o[0]+'</button>';}).join('')+
    '</div>';
  openSheet(h);
}
function quizPick(oi){_quizAns.push(oi);renderQuizQ();}
function spiritScore(answers){
  var sc={};Object.keys(SPIRITS).forEach(function(k){sc[k]=0;});
  answers.forEach(function(oi,qi){var w=QUIZ[qi][1][oi][1];Object.keys(w).forEach(function(k){sc[k]+=w[k];});});
  var best=null;Object.keys(SPIRITS).forEach(function(k){if(best===null||sc[k]>sc[best])best=k;});
  return best;
}
function finishQuiz(){
  var id=spiritScore(_quizAns);_quizAns=null;
  state.spirit={id:id,date:today()};save();
  celebrateBurst();showSpirit(id);
}
function showSpirit(id){
  var sp=SPIRITS[id];if(!sp){openQuiz();return;}
  var h='<div class="card" style="text-align:center"><div style="font-size:72px" aria-hidden="true">'+sp.e+'</div>'+
    '<div class="lbl" style="color:var(--tx2);margin-top:4px">YOUR SPIRIT SPECIES</div>'+
    '<h2 style="margin:4px 0 2px">'+sp.n+'</h2>'+
    '<div style="font-family:Georgia,serif;font-style:italic;color:var(--forest)">'+sp.tag+'</div>'+
    '<p class="muted" style="margin-top:12px">'+sp.d+'</p></div>'+
    '<div class="card"><div style="font-weight:600">🌍 In the wild</div><p class="muted" style="margin:8px 0 0">'+sp.hook+'</p>'+
    '<button class="btn" onclick="openCat(\''+sp.cat+'\')">Meet your kin →</button></div>'+
    '<button class="btn" onclick="shareSpirit()">📤 Share my spirit species</button>'+
    '<button class="btn ghost" onclick="openQuiz()">Retake the quiz</button>';
  var kin=SPIRIT_KIN[id];
  if(!state.guardian&&kin&&GUARDIANS.length){
    var kg=GUARDIANS.filter(function(x){return x.id===kin})[0];
    if(kg)h+='<div class="card"><div style="font-weight:600">🛡️ Your wild kin needs you</div>'+
      '<p class="muted" style="margin:8px 0 0">Every '+esc(sp.n.toLowerCase())+' spirit has an endangered kin in the real world: the '+esc(kg.name)+' - '+esc(kg.count)+'. You could stand for them.</p>'+
      '<button class="btn" onclick="openPledge(\''+kg.id+'\')">'+kg.emo+' Meet the '+esc(kg.name)+'</button></div>';
  }
  openSheet(h);
}
function shareSpirit(){
  var sp=state.spirit&&SPIRITS[state.spirit.id];if(!sp)return;
  var cv=document.createElement('canvas');cv.width=1080;cv.height=1080;var x=cv.getContext('2d');
  var g=x.createLinearGradient(0,0,1080,1080);g.addColorStop(0,'#2E6B4F');g.addColorStop(1,'#0B3D4C');x.fillStyle=g;x.fillRect(0,0,1080,1080);
  x.textAlign='center';
  x.font='500 44px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.85)';x.fillText('MY SPIRIT SPECIES',540,150);
  x.font='320px -apple-system,Segoe UI,Arial';x.fillText(sp.e,540,530);
  x.fillStyle='#ffffff';x.font='700 92px -apple-system,Segoe UI,Arial';x.fillText(sp.n,540,680);
  x.font='italic 44px Georgia,serif';x.fillStyle='rgba(255,255,255,.9)';x.fillText(sp.tag,540,748);
  x.font='600 46px -apple-system,Segoe UI,Arial';x.fillStyle='#B2F1CC';x.fillText('What\'s yours?',540,890);
  x.font='500 38px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.85)';x.fillText('🌿 Hopeling · small actions, real hope',540,990);
  cv.toBlob(function(blob){
    if(!blob){toast('Could not create image');return;}
    var file=new File([blob],'hopeling-spirit.png',{type:'image/png'});
    if(navigator.canShare&&navigator.canShare({files:[file]})){
      navigator.share({files:[file],title:'My spirit species',text:'I\'m a '+sp.n+' 🌿 What\'s your spirit species?'}).catch(function(){});
    }else{
      var url=URL.createObjectURL(blob);var a=document.createElement('a');a.href=url;a.download='hopeling-spirit.png';document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(url)},1000);toast('Image saved - share it anywhere 📤');
    }
  },'image/png');
}

/* ---- share card (canvas image) ---- */
function drawMiniGraph(x,ox,oy,cell){
  var weeks=40,gap=5,end=new Date();var d=new Date(end.getTime()-(weeks*7-1)*86400000);
  for(var w=0;w<weeks;w++){for(var r=0;r<7;r++){var key=dkey(d);var c=state.log[key]||0;
    x.fillStyle=c===0?'rgba(255,255,255,.16)':c===1?'#B2F1CC':c===2?'#63c48b':'#ffffff';
    x.fillRect(ox+w*(cell+gap),oy+r*(cell+gap),cell,cell);d=new Date(d.getTime()+86400000);}}
}
function shareImpact(){
  var lvl=levelForXp(state.xp);var acts=Object.keys(state.done).length;
  var cv=document.createElement('canvas');cv.width=1080;cv.height=1080;var x=cv.getContext('2d');
  var g=x.createLinearGradient(0,0,1080,1080);g.addColorStop(0,'#2E6B4F');g.addColorStop(1,'#0B3D4C');x.fillStyle=g;x.fillRect(0,0,1080,1080);
  x.fillStyle='#ffffff';x.textAlign='center';
  x.font='600 66px -apple-system,Segoe UI,Arial';x.fillText('🌿 Hopeling',540,150);
  x.font='italic 40px Georgia,serif';x.fillStyle='rgba(255,255,255,.9)';x.fillText('Small actions. Real hope.',540,214);
  x.fillStyle='#ffffff';x.font='700 240px -apple-system,Segoe UI,Arial';x.fillText(String(state.streak),540,500);
  x.font='500 46px -apple-system,Segoe UI,Arial';x.fillText('day streak 🔥',540,560);
  x.font='600 42px -apple-system,Segoe UI,Arial';x.fillText('✅ '+acts+' actions    ·    Level '+lvl,540,662);
  drawMiniGraph(x,80,720,18);
  x.font='500 36px -apple-system,Segoe UI,Arial';x.fillStyle='rgba(255,255,255,.9)';x.fillText('Join me - every action counts',540,1010);
  cv.toBlob(function(blob){
    if(!blob){toast('Could not create image');return;}
    var file=new File([blob],'hopeling-impact.png',{type:'image/png'});
    if(navigator.canShare&&navigator.canShare({files:[file]})){
      navigator.share({files:[file],title:'My Hopeling impact',text:'Small actions, real hope 🌿'}).catch(function(){});
    }else{
      var url=URL.createObjectURL(blob);var a=document.createElement('a');a.href=url;a.download='hopeling-impact.png';document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(url)},1000);toast('Image saved - share it anywhere 📤');
    }
  },'image/png');
}
function downloadReminder(){
  var t=prompt('Daily reminder time (24h, HH:MM):','18:00');if(t==null)return;
  var m=/^([01]?\d|2[0-3]):([0-5]\d)$/.exec(t.trim());if(!m){toast('Use HH:MM, e.g. 18:00');return;}
  var d=new Date(),ds=''+d.getFullYear()+('0'+(d.getMonth()+1)).slice(-2)+('0'+d.getDate()).slice(-2);
  var hh=('0'+m[1]).slice(-2),mm=m[2];
  var ics='BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Hopeling//Reminder//EN\r\nBEGIN:VEVENT\r\nUID:hopeling-daily-'+Date.now()+'@hopeling\r\nDTSTAMP:'+ds+'T000000Z\r\nDTSTART:'+ds+'T'+hh+mm+'00\r\nRRULE:FREQ=DAILY\r\nSUMMARY:🌿 Hopeling - one small action today\r\nDESCRIPTION:Learn one thing\\, do one thing. Keep your streak alive: https://hopeling.app/\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
  var blob=new Blob([ics],{type:'text/calendar'});var url=URL.createObjectURL(blob);
  var a=document.createElement('a');a.href=url;a.download='hopeling-daily-reminder.ics';document.body.appendChild(a);a.click();a.remove();
  setTimeout(function(){URL.revokeObjectURL(url)},1000);
  toast('Open the file to add it to your calendar 📅');
}
/* register service worker for offline/install */
if('serviceWorker'in navigator){window.addEventListener('load',function(){
  navigator.serviceWorker.register('sw.js').then(function(reg){
    reg.addEventListener('updatefound',function(){
      var nw=reg.installing;if(!nw)return;
      nw.addEventListener('statechange',function(){
        if(nw.state==='activated'&&navigator.serviceWorker.controller){
          toast('🌿 App updated - close & reopen to load it');
        }
      });
    });
  }).catch(function(){});
});}

/* ---- self-updating content: fetch content.json online, cache offline ---- */
var APP_V='v65';var DISPLAY_V='1.0';
var BUNDLED_VERSION=1, contentUpdated='';
function normalizeCourses(list){(list||[]).forEach(function(c){(c.lessons||[]).forEach(function(l){if(!l.quiz&&l.q!==undefined)l.quiz=[{q:l.q,opts:l.opts,a:l.a}];if(!l.quiz)l.quiz=[];if(l.body===undefined)l.body='';});});return list;}
function applyContent(d){
  if(!d)return;
  if(d.categories)CATS=d.categories;
  if(d.actions)ACTS=d.actions;
  if(d.courses)COURSES=normalizeCourses(d.courses);
  if(d.facts)FACTS=d.facts;
  if(d.stories)STORIES=d.stories;
  if(d.news)NEWS=d.news;
  if(d.guardians)GUARDIANS=d.guardians;
  if(d.travel)TRAVEL=d.travel;
  EVENT=d.event||null;
  if(d.updated)contentUpdated=d.updated;
  ACT_CATS={};CATS.forEach(function(c){(c.acts||[]).forEach(function(sl){(ACT_CATS[sl]=ACT_CATS[sl]||[]).push(c.slug);});});
}
function loadContent(){
  var cached=LS.get('contentCache',null);
  if(cached&&cached.version&&cached.version>=BUNDLED_VERSION)applyContent(cached);
  fetch('content.json?ts='+Date.now(),{cache:'no-store'}).then(function(r){return r.ok?r.json():null;}).then(function(d){
    if(d&&d.categories){LS.set('contentCache',d);applyContent(d);if(state.onboarded)render();}
  }).catch(function(){});
}
/* boot */
normalizeCourses(COURSES);migrateRings();migrateCatCounts();
state.kid=false; /* kid mode parked until the full kids world ships (see KIDS-MODE.md) */
applyTheme();applyKid();buildNav();
try{if(navigator.storage&&navigator.storage.persist)navigator.storage.persist().catch(function(){});}catch(e){}
try{var _goq=(typeof location!=='undefined'&&location.search.match(/[?&]go=(act|grove)/))?RegExp.$1:null;if(_goq){setTimeout(function(){if(_goq==='act')go('act');else openGrove();},400);try{history.replaceState(null,'',location.pathname);}catch(e2){}}}catch(e){}
render();maybeRemind();
(function breatheOpen(){
  try{
    if(typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    var sky={'sky-dawn':'linear-gradient(180deg,#ffeccb,#fdf8ec)','sky-day':'linear-gradient(180deg,#e3f4ec,#f4faf3)','sky-dusk':'linear-gradient(180deg,#ffd9b3,#f9efe2)','sky-night':'linear-gradient(180deg,#0d1b2b,#13251f)'};
    var k=(typeof skyClass==='function')?skyClass():'sky-day';
    var b=document.createElement('div');b.className='bopen';b.setAttribute('aria-hidden','true');
    b.style.background=sky[k]||sky['sky-day'];
    b.innerHTML='<span class="lf">🍃</span>';
    document.body.appendChild(b);
    setTimeout(function(){if(b.parentNode)b.parentNode.removeChild(b);},1400);
  }catch(e){}
})();
if(!state.onboarded)showCeremony();
loadContent();
