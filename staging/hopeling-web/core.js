/* Hopeling - core.js (split from Hopeling.html, shared global scope, load order matters) */
/* ---------------- persistent state ---------------- */
var LS = { get:function(k,d){try{var v=localStorage.getItem('wh_'+k);return v==null?d:JSON.parse(v)}catch(e){return d}},
           set:function(k,v){try{localStorage.setItem('wh_'+k,JSON.stringify(v))}catch(e){}} };
var state = {
  xp: LS.get('xp',0), streak: LS.get('streak',0), last: LS.get('last',null),
  done: LS.get('done',{}), lessons: LS.get('lessons',{}), badges: LS.get('badges',{}),
  totals: LS.get('totals',{}), causes: LS.get('causes',[]), theme: LS.get('theme',null),
  onboarded: LS.get('onboarded',false), log: LS.get('log',{}), remind: LS.get('remind',false),
  lastRemind: LS.get('lastRemind',null), freezes: LS.get('freezes',0),
  customActions: LS.get('customActions',{}), missionWeek: LS.get('missionWeek',null), chDone: LS.get('chDone',null),
  missions: LS.get('missions',{}), missionIds: LS.get('missionIds',[]), lastRepair: LS.get('lastRepair',null),
  milestones: LS.get('milestones',{}), recapWeek: LS.get('recapWeek',null), lastBackup: LS.get('lastBackup',null),
  simple: LS.get('simple',false), kid: LS.get('kid',false), rings: LS.get('rings',null),
  eventProg: LS.get('eventProg',{}), eventBadges: LS.get('eventBadges',[]),
  spirit: LS.get('spirit',null), spiritDismissed: LS.get('spiritDismissed',false),
  catCounts: LS.get('catCounts',null), guardian: LS.get('guardian',null), guardianNews: LS.get('guardianNews',{}),
  trip: LS.get('trip',null), tripsDone: LS.get('tripsDone',0), visits: LS.get('visits',{})
};
var SAVE_KEYS=['xp','streak','last','done','lessons','badges','totals','causes','theme','onboarded','log','remind','lastRemind','freezes','customActions','missionWeek','missions','missionIds','lastRepair','chDone','milestones','recapWeek','lastBackup','simple','kid','rings','eventProg','eventBadges','spirit','spiritDismissed','catCounts','guardian','guardianNews','trip','tripsDone','visits'];
function save(){SAVE_KEYS.forEach(function(k){LS.set(k,state[k])});}
function dkey(d){return d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2)+'-'+('0'+d.getDate()).slice(-2);}
function today(){return dkey(new Date());}
function logToday(){var t=today();state.log[t]=(state.log[t]||0)+1;}

function levelForXp(xp){var lvl=1;while(xp>=Math.floor(100*Math.pow(lvl,1.5))&&lvl<99){xp-=Math.floor(100*Math.pow(lvl,1.5));lvl++;}return lvl;}
var LEVEL_NAMES=["Seed","Sprout","Seedling","Sapling","Young Tree","Grove Keeper","Forest Friend","Wild Guardian","Earth Ally","Hopeling Champion"];
function daysBetween(a,b){return Math.round((new Date(b)-new Date(a))/86400000);}
function touchStreak(){
  var t=today();if(state.last===t)return;
  if(state.last){
    var gap=daysBetween(state.last,t);
    if(gap===1){state.streak++;}
    else if(gap===2&&(state.freezes||0)>0){state.freezes--;state.streak++;state._freezeUsed=true;}
    else {if(state.streak>=3)addRing(state.streak,state.last);state.streak=1;}
  } else {state.streak=1;}
  state.last=t;
  if(state.streak>0&&state.streak%7===0&&(state.freezes||0)<3){state.freezes=(state.freezes||0)+1;state._freezeEarned=true;}
  GROVE_FRIENDS.forEach(function(fr){if(state.streak===fr[0]&&!state.milestones['friend'+fr[0]]){state.milestones['friend'+fr[0]]=1;state._newFriend=fr[1]+' '+fr[2].replace(/^an? /,'');}});
}
/* Tree rings: past streaks (3+ days) stay part of the grove's story. */
function addRing(n,end){state.rings=state.rings||[];state.rings.unshift({n:n,end:end});state.rings=state.rings.slice(0,24);}
function migrateRings(){
  if(state.rings!==null&&state.rings!==undefined)return;
  var days=Object.keys(state.log).filter(function(d){return state.log[d]>0}).sort();
  var rings=[],run=1;
  for(var i=1;i<=days.length;i++){
    var isEnd=(i===days.length)||daysBetween(days[i-1],days[i])!==1;
    if(!isEnd){run++;continue;}
    var endDay=days[i-1];
    if(run>=3&&daysBetween(endDay,today())>1)rings.push({n:run,end:endDay});
    run=1;
  }
  rings.reverse();
  state.rings=rings.slice(0,24);save();
}
function ringWhen(end){var d=new Date(end);var M=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];return M[d.getMonth()]+' '+d.getFullYear();}

/* Repair: if you missed exactly yesterday, restore the streak (hope over guilt). */
function weekAgoStats(){
  var total=0,days=0;
  for(var i=1;i<=7;i++){var c=state.log[dkey(new Date(Date.now()-86400000*i))]||0;if(c>0){days++;total+=c;}}
  return [total,days];
}
function dismissRecap(){state.recapWeek=weekKey();save();render();}
function backupDue(){
  if(state.xp<50)return false;
  return state.lastBackup?daysBetween(state.lastBackup,today())>=14:true;
}
function repairable(){return state.last&&daysBetween(state.last,today())===2&&state.streak>=2&&state.lastRepair!==today();}
function repairStreak(){state.last=dkey(new Date(Date.now()-86400000));state.lastRepair=today();save();toast('Streak repaired 🌱 - do today\'s action to keep it!');render();}

/* ---------------- content ---------------- */
var CATS=[
 {slug:'sea-turtles',emo:'🐢',name:'Sea Turtles',iucn:'EN',sum:'6 of 7 sea turtle species are threatened; plastic and bycatch are top threats.',threats:[['Plastic pollution','Turtles mistake floating bags for jellyfish.','Ocean Conservancy'],['Fisheries bycatch','Accidental capture in nets and longlines.','NOAA']],hope:[['Costa Rica nest protection','Beach patrols protect nests from poaching and light pollution.']],acts:['refuse-plastic','beach-cleanup','sustainable-seafood']},
 {slug:'whales',emo:'🐋',name:'Whales',iucn:'VU',sum:'Many great whales are recovering after the 1986 whaling moratorium.',threats:[['Ship strikes & entanglement','Fishing gear and vessels injure whales.','NOAA']],hope:[['Humpbacks bounce back','Some populations recovered to near pre-whaling numbers.']],acts:['sustainable-seafood','donate','sign-petition']},
 {slug:'sharks',emo:'🦈',name:'Sharks',iucn:'VU',sum:'About a third of sharks and rays face extinction, largely from overfishing.',threats:[['Overfishing & finning','Slow-growing sharks can\'t keep up with fishing pressure.','IUCN']],hope:[['Palau shark sanctuary','A whole national EEZ closed to commercial shark fishing.']],acts:['sustainable-seafood','sign-petition','donate']},
 {slug:'dolphins',emo:'🐬',name:'Dolphins',iucn:'LC',sum:'Most dolphins are stable, but river dolphins and the vaquita are critical.',threats:[['Bycatch & pollution','Nets and noise threaten coastal dolphins.','IUCN']],hope:[['Vaquita protection zone','Emergency net bans aim to save the rarest marine mammal.']],acts:['sustainable-seafood','refuse-plastic','sign-petition']},
 {slug:'elephants',emo:'🐘',name:'Elephants',iucn:'EN',sum:'Keystone species that disperse seeds of over 100 tree species.',threats:[['Poaching & habitat loss','Ivory demand and shrinking range.','WWF']],hope:[['Community conservancies','Local stewardship in Kenya protects elephants and big cats.']],acts:['donate','sign-petition','educate-child']},
 {slug:'gorillas',emo:'🦍',name:'Gorillas',iucn:'CR',sum:'Mountain gorillas rose above 1,000 - community tourism funded the recovery.',threats:[['Disease & habitat loss','Human disease transmission is a real risk.','WCS']],hope:[['Mountain gorilla comeback','Numbers rose thanks to community-based protection.']],acts:['donate','switch-palm-oil','educate-child']},
 {slug:'orangutans',emo:'🦧',name:'Orangutans',iucn:'CR',sum:'Palm-oil-driven deforestation is the primary threat to their forests.',threats:[['Deforestation for palm oil','Forest clearing destroys their only habitat.','Rainforest Alliance']],hope:[['Certified palm oil','Demand for RSPO-certified oil reduces forest loss.']],acts:['switch-palm-oil','donate','sign-petition']},
 {slug:'tigers',emo:'🐅',name:'Tigers',iucn:'EN',sum:'Wild tigers are rising in India, Nepal and Bhutan.',threats:[['Poaching & prey loss','Corridors and prey protection underpin recovery.','WWF']],hope:[['India\'s tigers doubled','More than doubled since 2006.']],acts:['donate','switch-palm-oil','sign-petition']},
 {slug:'pandas',emo:'🐼',name:'Pandas',iucn:'VU',sum:'Downlisted from Endangered to Vulnerable in 2016 - a real success.',threats:[['Habitat fragmentation','Bamboo corridors are being reconnected.','IUCN']],hope:[['A conservation success','Decades of habitat protection paid off.']],acts:['donate','educate-child']},
 {slug:'rhinos',emo:'🦏',name:'Rhinos',iucn:'CR',sum:'Three of five rhino species are Critically Endangered; poaching is the driver.',threats:[['Poaching for horn','Anti-poaching and demand reduction are the response.','IUCN']],hope:[['Anti-poaching works','Protected reserves are stabilizing some populations.']],acts:['donate','sign-petition']},
 {slug:'wolves',emo:'🐺',name:'Wolves',iucn:'LC',sum:'Apex predators whose return reshapes whole ecosystems.',threats:[['Persecution & habitat loss','Conflict with livestock drives culling.','IUCN']],hope:[['Yellowstone rewilding','Returning wolves restored rivers and biodiversity.']],acts:['sign-petition','donate','educate-child']},
 {slug:'foxes',emo:'🦊',name:'Foxes',iucn:'LC',sum:'Mostly stable; urban coexistence and rodenticide reduction help most.',threats:[['Rodenticide poisoning','Secondary poisoning up the food chain.','Xerces Society']],hope:[['Rodenticide-free towns','Communities switching to safer pest control.']],acts:['reduce-pesticides','educate-child']},
 {slug:'polar-bears',emo:'🐻‍❄️',name:'Polar Bears',iucn:'VU',sum:'Polar bears hunt seals from sea ice, so their future is tied to how much ice the Arctic keeps.',threats:[['Shrinking sea ice','Shorter ice seasons mean fewer chances to hunt seals.','IUCN']],hope:[['Nations acted before','Ending unregulated hunting in 1973 brought numbers back.']],acts:['walk-dont-drive','green-energy','meatless-meal']},
 {slug:'penguins',emo:'🐧',name:'Penguins',iucn:'EN',sum:'Many penguin species decline as fish stocks and sea ice shift.',threats:[['Overfishing & warming','Less food and shrinking ice.','NOAA']],hope:[['Marine protected areas','No-take zones rebuild the fish penguins depend on.']],acts:['sustainable-seafood','refuse-plastic','donate']},
 {slug:'dogs',emo:'🐕',name:'Dogs',iucn:'LC',sum:'Adoption and spay/neuter directly reduce shelter euthanasia.',threats:[['Shelter overcrowding','Spay/neuter is the biggest lever on intake.','ASPCA']],hope:[['Adoption saves two','The one taken, and the next one admitted.']],acts:['adopt','spay-neuter','report-abuse']},
 {slug:'cats',emo:'🐈',name:'Cats',iucn:'LC',sum:'TNR humanely stabilizes community cat populations; indoor cats protect birds.',threats:[['Overpopulation','TNR (trap-neuter-return) is the humane tool.','ASPCA']],hope:[['TNR communities','Stable, healthier community cat colonies.']],acts:['adopt','spay-neuter','cats-indoors']},
 {slug:'birds',emo:'🦜',name:'Birds',iucn:'NT',sum:'North America lost ~3 billion birds since 1970; windows and cats are key threats.',threats:[['Windows & outdoor cats','Bird-safe glass and native plants cut mortality.','Cornell Lab']],hope:[['Native plant gardens','Double the insect food for backyard birds.']],acts:['bird-feeder','native-plant','cats-indoors']},
 {slug:'bees',emo:'🐝',name:'Bees & Pollinators',iucn:'VU',sum:'Pollinators support ~75% of leading food crops.',threats:[['Pesticides & habitat loss','Neonicotinoids and monoculture reduce forage.','UNEP']],hope:[['Bring back the pollinators','Pesticide-free pledges rebuild corridors.']],acts:['native-plant','bee-hotel','reduce-pesticides']},
 {slug:'oceans',emo:'🌊',name:'Oceans',iucn:'NA',sum:'Oceans absorb ~25% of CO₂; overfishing and plastic are top stressors.',threats:[['Plastic & overfishing','8M+ tonnes of plastic enter the ocean yearly.','UNEP']],hope:[['30x30 goal','A push to protect 30% of the ocean by 2030.']],acts:['refuse-plastic','beach-cleanup','sustainable-seafood']},
 {slug:'coral-reefs',emo:'🐟',name:'Coral Reefs',iucn:'CR',sum:'Reefs support ~25% of marine species; heat waves cause bleaching.',threats:[['Warming seas','Reducing local stressors aids heat resilience.','NOAA']],hope:[['Heat-resilient coral','Restoration shows promising survival.']],acts:['refuse-plastic','meatless-meal','donate']},
 {slug:'forests',emo:'🌳',name:'Forests',iucn:'NA',sum:'Forests host ~80% of land biodiversity; deforestation is slowing in places.',threats:[['Deforestation','Beef, soy and palm oil drive most forest loss.','Our World in Data']],hope:[['Rewilding & certification','Deforestation-free supply chains reduce pressure.']],acts:['switch-palm-oil','meatless-meal','plant-tree']},
 {slug:'freshwater',emo:'💧',name:'Freshwater',iucn:'NA',sum:'Freshwater species populations fell ~83% since 1970.',threats:[['Dams & pollution','Rivers and wetlands are heavily altered.','WWF']],hope:[['River restoration','Removing dams brings fish and wildlife back.']],acts:['save-water','reduce-pesticides','refuse-plastic']},
 {slug:'farm-animals',emo:'🐄',name:'Farm Animals',iucn:'NA',sum:'Reducing meat and choosing higher-welfare products cut the most suffering.',threats:[['Intensive farming','Diet shifts are a high-impact individual action.','Our World in Data']],hope:[['Higher-welfare choices','Reduction and welfare gains add up fast.']],acts:['meatless-meal','reduce-food-waste','educate-child']}
];

var ACTS={
 'refuse-plastic':{t:'Refuse one single-use plastic',why:'8M+ tonnes of plastic enter the ocean yearly, harming turtles, seabirds and whales.',imp:'~150 items/year kept out of waterways.',diff:1,mod:'home',cost:'Free',min:2,metric:'plastic_kg',val:0.02,ev:['UNEP'],steps:['Carry a reusable bottle/bag','Say no to straws & cutlery','Log it']},
 'meatless-meal':{t:'Have one meatless meal',why:'Animal agriculture is a top driver of land use, emissions and farmed-animal suffering.',imp:'Saves ~1-2 kg CO₂e vs a beef meal.',diff:1,mod:'home',cost:'Free',min:30,metric:'carbon_kg',val:1.5,ev:['Our World in Data'],steps:['Pick a plant-based recipe','Cook & enjoy','Log it']},
 'switch-palm-oil':{t:'Switch a product to palm-oil-free',why:'Unsustainable palm oil drives tropical deforestation that destroys orangutan, tiger and elephant habitat.',imp:'Pressures supply chains toward certified sources.',diff:1,mod:'home',cost:'Free',min:5,metric:'generic',val:1,ev:['Rainforest Alliance'],steps:['Check labels for palm oil','Choose RSPO-certified / palm-oil-free','Repeat next shop']},
 'beach-cleanup':{t:'Pick up 10 pieces of trash',why:'Coastal litter is ingested by marine life; small cleanups add up across communities.',imp:'10 items × many people = tonnes diverted.',diff:1,mod:'outdoor',cost:'Free',min:15,metric:'plastic_kg',val:0.1,ev:['Ocean Conservancy'],steps:['Bring a bag & gloves','Collect 10+ items safely','Dispose/recycle & log']},
 'native-plant':{t:'Plant one native flower',why:'Native plants feed local pollinators and birds far better than ornamentals.',imp:'Can support dozens of bee & butterfly species.',diff:2,mod:'outdoor',cost:'Low',min:30,metric:'generic',val:1,ev:['Xerces Society'],steps:['Find a native species for your region','Plant in sun','Water until established']},
 'bee-hotel':{t:'Install a bee hotel',why:'Solitary bees need nesting cavities lost to development.',imp:'Supports mason & leafcutter bees.',diff:2,mod:'outdoor',cost:'Low',min:120,metric:'generic',val:1,ev:['Xerces Society'],steps:['Buy or build with untreated wood','Mount in morning sun ~1.5m high','Clean yearly']},
 'bird-feeder':{t:'Set up a bird feeder & water',why:'Clean feeders and window decals help birds and prevent collisions.',imp:'Reduces window-strike mortality.',diff:1,mod:'outdoor',cost:'Low',min:20,metric:'generic',val:1,ev:['Cornell Lab'],steps:['Add feeder + shallow water','Apply window decals','Clean weekly']},
 'sustainable-seafood':{t:'Choose sustainable seafood',why:'Overfishing and bycatch threaten sharks, turtles and fish stocks.',imp:'Reduces pressure on collapsing stocks.',diff:2,mod:'financial',cost:'Low',min:10,metric:'generic',val:1,ev:['NOAA Fisheries'],steps:['Check a seafood guide','Pick "Best Choice" options','Ask your vendor']},
 'cats-indoors':{t:'Keep cats indoors or supervised',why:'Free-roaming cats are a leading human-linked cause of bird deaths.',imp:'Protects local birds - and keeps cats safer.',diff:1,mod:'home',cost:'Free',min:5,metric:'generic',val:1,ev:['American Bird Conservancy'],steps:['Try a catio or leash walks','Enrich indoor play','Add a bell as backup']},
 'reduce-food-waste':{t:'Save one meal from the bin',why:'Food waste wastes the land, water and animal lives used to produce it.',imp:'Cuts emissions and demand on farming.',diff:1,mod:'home',cost:'Free',min:10,metric:'carbon_kg',val:0.8,ev:['Our World in Data'],steps:['Plan portions','Store leftovers well','Use up before shopping']},
 'save-water':{t:'Cut water use today',why:'Freshwater habitats and their species are among the most threatened on Earth.',imp:'Less demand on rivers and wetlands.',diff:1,mod:'home',cost:'Free',min:5,metric:'generic',val:1,ev:['WWF'],steps:['Shorter shower','Fix a drip','Turn off the tap while scrubbing']},
 'adopt':{t:'Adopt or foster from a shelter',why:'Shelters are overcrowded; adoption and fostering save lives and free space.',imp:'Each adoption can save two animals.',diff:3,mod:'outdoor',cost:'Med',min:240,metric:'animals',val:1,ev:['ASPCA'],steps:['Find a local shelter/rescue','Meet & match','Adopt or foster & log']},
 'spay-neuter':{t:'Support spay/neuter',why:'The most effective way to reduce shelter intake and euthanasia.',imp:'One prevented litter averts dozens of shelter animals.',diff:3,mod:'financial',cost:'Med',min:60,metric:'animals',val:2,ev:['ASPCA'],steps:['Book a clinic or sponsor one','Include community cats (TNR)','Log it']},
 'donate':{t:'Donate to a vetted org',why:'Effective orgs turn funds into ranger patrols, habitat and rescue capacity.',imp:'Small recurring gifts fund real anti-poaching work.',diff:3,mod:'financial',cost:'Med',min:10,metric:'money',val:10,ev:['WWF'],steps:['Pick a vetted org','Give what you can','Log the amount']},
 'sign-petition':{t:'Sign a science-backed petition',why:'Public pressure shifts policy on protected areas and trade bans.',imp:'Has preceded real bans and marine reserves.',diff:1,mod:'online',cost:'Free',min:3,metric:'generic',val:1,ev:['UNEP'],steps:['Choose a current campaign','Sign & verify email','Share once']},
 'reduce-pesticides':{t:'Go pesticide-free in your garden',why:'Pesticides harm pollinators and cause secondary poisoning up the food chain.',imp:'Your yard becomes a refuge for bees & birds.',diff:2,mod:'outdoor',cost:'Free',min:20,metric:'generic',val:1,ev:['Xerces Society'],steps:['Stop broad-spectrum sprays','Use physical/biological controls','Avoid rodenticides']},
 'plant-tree':{t:'Plant or fund a native tree',why:'Reforestation restores habitat and captures carbon with native species.',imp:'One native tree supports hundreds of interactions.',diff:2,mod:'outdoor',cost:'Low',min:60,metric:'trees',val:1,ev:['The Nature Conservancy'],steps:['Choose a native species','Plant or fund via a vetted program','Log it']},
 'educate-child':{t:'Teach a child one animal fact',why:'Early nature connection is the strongest predictor of lifelong conservation behavior.',imp:'One fact plants a multi-decade ripple of care.',diff:1,mod:'home',cost:'Free',min:10,metric:'generic',val:1,ev:['National Geographic'],steps:['Pick a fact from the app','Share it with a child','Do a related activity']},
 'report-abuse':{t:'Learn how to report animal abuse',why:'Fast, correct reporting gets animals help and triggers enforcement.',imp:'The right hotline can save a life in minutes.',diff:1,mod:'online',cost:'Free',min:10,metric:'generic',val:1,ev:['ASPCA'],steps:['Save local animal-control & rescue numbers','Learn what to document','Share with neighbors']}
};

var FACTS=[
 ['A single great whale sequesters ~33 tons of CO₂ over its lifetime.','IUCN','whales'],
 ['Elephants can recognize themselves in a mirror - a rare marker of self-awareness.','PNAS','elephants'],
 ['One in three bites of food we eat depends on pollinators.','FAO','bees'],
 ['A sea turtle\'s sex is set by nest temperature - warmer sand yields more females.','NOAA','sea-turtles'],
 ['Sharks have existed for ~450 million years - older than trees.','National Geographic','sharks'],
 ['Octopuses have three hearts and blue, copper-based blood.','NOAA','oceans'],
 ['Coral reefs cover under 1% of the ocean floor but support ~25% of marine species.','NOAA','coral-reefs'],
 ['India\'s wild tiger population has more than doubled since 2006.','WWF','tigers'],
 ['Returning wolves to Yellowstone helped rivers change course by reviving vegetation.','NPS','wolves'],
 ['A group of flamingos is called a "flamboyance".','National Geographic','birds']
];
var STORIES=[
 ['🎉 Victory','Giant pandas leave the Endangered list','Decades of habitat protection moved pandas to Vulnerable in 2016.'],
 ['🎉 Victory','India\'s tigers more than double','Coordinated reserves and anti-poaching drove the recovery since 2006.'],
 ['💚 Rescue','Oiled penguins released after rehab','Hundreds cleaned, rehabilitated and returned to the wild by a coastal center.'],
 ['🎉 Victory','Palau creates a vast shark sanctuary','Palau banned commercial shark fishing across its entire EEZ.'],
 ['🎉 Victory','Mountain gorillas pass 1,000','Community-based tourism funded a real population rebound.']
];
var NEWS=[
 {d:'2026-07-01',tag:'🎉 Comeback',t:'The Iberian lynx keeps bouncing back',x:'From about 100 animals in 2002 to thousands today - downlisted from Endangered to Vulnerable. Coordinated breeding and rabbit recovery did it.',src:'IUCN'},
 {d:'2026-06-29',tag:'💙 Recovery',t:'Humpback whales near pre-whaling numbers',x:'Several Southern Hemisphere populations have largely recovered since the 1986 whaling moratorium - proof that protection works at ocean scale.',src:'NOAA'},
 {d:'2026-06-27',tag:'🦅 Milestone',t:'California condors keep climbing',x:'From just 22 birds in the 1980s to over 500 today, more than half flying free. One of the great rescue stories in conservation.',src:'USFWS'},
 {d:'2026-06-25',tag:'🌳 Rewilding',t:'European bison roam free again',x:'Once extinct in the wild, thousands now graze rewilded landscapes across Europe - restoring meadows and biodiversity as they go.',src:'Rewilding Europe'},
 {d:'2026-06-22',tag:'🌊 Protection',t:'Momentum builds for protecting the high seas',x:'Nations continue ratifying the ocean treaty aimed at protecting 30% of international waters - habitats sharks, whales and turtles depend on.',src:'UN'}
];
var CHALLENGES=[['No Plastic Week',100],['Meatless Monday',60],['Pick up 10 pieces of trash',30],['Plant native flowers',50],['Bird water week',40]];
var COURSES=[
 {slug:'ocean-pollution',t:'Ocean Pollution 101',d:'How plastic affects marine life - and what works.',badge:'🌊',
  lessons:[{t:'Where ocean plastic comes from',min:6,q:'Most ocean plastic originates…',opts:['On land, via rivers','From ships only','From coral'],a:0},
           {t:'Impact on marine animals',min:7,q:'A common plastic harm to turtles is…',opts:['Mistaking bags for jellyfish','Too much food','Bright colors'],a:0},
           {t:'Solutions that work',min:6,q:'The highest-impact first step is…',opts:['Reduction','Ignoring it','More packaging'],a:0}]},
 {slug:'endangered-species',t:'Endangered Species & the Red List',d:'How extinction risk is measured and reversed.',badge:'🦏',
  lessons:[{t:'Reading the Red List',min:6,q:'CR stands for…',opts:['Critically Endangered','Common','Recovered'],a:0},
           {t:'Recovery stories',min:7,q:'Which recovered recently?',opts:['Giant pandas','Dodo','-'],a:0},
           {t:'Support recovery',min:5,q:'What helps recovery most?',opts:['Habitat & corridors','Nothing','Less water'],a:0}]},
 {slug:'ethical-consumerism',t:'Ethical Consumerism',d:'Palm oil, seafood and cruelty-free choices.',badge:'🛒',
  lessons:[{t:'Reading labels',min:6,q:'Certified palm oil is labeled…',opts:['RSPO','Random','None'],a:0},
           {t:'High-impact swaps',min:7,q:'A high-impact food swap is…',opts:['Less beef','More beef','More plastic'],a:0}]},
 {slug:'biodiversity',t:'Biodiversity Basics',d:'Why variety of life keeps ecosystems (and us) healthy.',badge:'🌿',
  lessons:[{t:'What is biodiversity',min:6,q:'Biodiversity includes…',opts:['Genes, species & ecosystems','Only big animals','Only plants'],a:0},
           {t:'Why it matters to people',min:7,q:'Biodiversity gives us…',opts:['Food, medicine & clean water','Nothing useful','Only scenery'],a:0},
           {t:'Protecting it locally',min:5,q:'A local win for biodiversity is…',opts:['Native plants & no pesticides','Concrete','More lawn'],a:0}]}
];
var CAUSE_CHIPS=[['oceans','🌊 Oceans'],['farm-animals','🐄 Farm animals'],['elephants','🐘 Wildlife'],['dogs','🐕 Pets'],['bees','🐝 Pollinators'],['forests','🌳 Forests'],['birds','🦜 Birds'],['sharks','🦈 Marine life']];

function getAct(slug){return ACTS[slug]||(state.customActions&&state.customActions[slug]);}
function allActSlugs(){return Object.keys(ACTS).concat(Object.keys(state.customActions||{}));}
var KID_OK={'refuse-plastic':1,'beach-cleanup':1,'native-plant':1,'bird-feeder':1,'cats-indoors':1,'reduce-food-waste':1,'save-water':1,'educate-child':1,'meatless-meal':1,'compost-scraps':1,'wildlife-window':1,'secondhand-first':1,'citizen-science':1,'walk-dont-drive':1,'plant-milk':1,'tree-search':1,'fashion-detox':1};
function isKidOk(slug){return !!KID_OK[slug]||slug.indexOf('custom-')===0;}
var ACT_CATS={};CATS.forEach(function(c){c.acts.forEach(function(sl){(ACT_CATS[sl]=ACT_CATS[sl]||[]).push(c.slug);});});

/* Weekly missions */
var MISSION_POOL=[
 {id:'act3',t:'Take 3 actions',kt:'Hero training: 3 kind actions',type:'actions',n:3,xp:40},
 {id:'ocean2',t:'2 ocean actions',kt:'Ocean rescuer: 2 ocean actions',type:'category',cat:'oceans',n:2,xp:40},
 {id:'learn1',t:'Finish 1 lesson',kt:'Discover a wild secret: 1 lesson',type:'lessons',n:1,xp:30},
 {id:'medium2',t:'2 medium+ actions',kt:'Brave helper: 2 bigger actions',type:'diffmin',diff:2,n:2,xp:40},
 {id:'act5',t:'Take 5 actions',kt:'Super helper: 5 kind actions',type:'actions',n:5,xp:60},
 {id:'high1',t:'1 high-impact action',kt:'Big heart: 1 big action (with a grown-up)',type:'diffmin',diff:3,n:1,xp:50},
 {id:'learn2',t:'Finish 2 lessons',kt:'Wild scholar: 2 lessons',type:'lessons',n:2,xp:50}
];
function weekKey(){var d=new Date();var oj=new Date(d.getFullYear(),0,1);var w=Math.ceil((((d-oj)/86400000)+oj.getDay()+1)/7);return d.getFullYear()+'-W'+w;}
function ensureMissions(){
  if(state.missionWeek!==weekKey()){
    state.missionWeek=weekKey();state.missions={};
    var wk=weekKey(),h=0;for(var i=0;i<wk.length;i++)h=(h*31+wk.charCodeAt(i))>>>0;
    var chosen=[];[h,h>>>3,h>>>6,h>>>9].forEach(function(v){var idx=v%MISSION_POOL.length;if(chosen.indexOf(idx)<0&&chosen.length<3)chosen.push(idx);});
    for(var j=0;j<MISSION_POOL.length&&chosen.length<3;j++)if(chosen.indexOf(j)<0)chosen.push(j);
    state.missionIds=chosen.map(function(i){return MISSION_POOL[i].id;});save();
  }
}
function currentMissions(){ensureMissions();return (state.missionIds||[]).map(function(id){return MISSION_POOL.filter(function(m){return m.id===id;})[0];}).filter(Boolean);}
function bumpMissions(kind,slug){
  ensureMissions();var act=getAct(slug);var cats=ACT_CATS[slug]||[];
  currentMissions().forEach(function(m){
    var done=state.missions[m.id]||0;if(done>=m.n)return;var hit=false;
    if(kind==='action'){
      if(m.type==='actions')hit=true;
      else if(m.type==='category'&&cats.indexOf(m.cat)>=0)hit=true;
      else if(m.type==='diffmin'&&act&&act.diff>=m.diff)hit=true;
    } else if(kind==='lesson'&&m.type==='lessons')hit=true;
    if(hit){state.missions[m.id]=done+1;if(state.missions[m.id]>=m.n){state.xp+=m.xp;toast('🎯 Mission done: '+((state.kid&&m.kt)?m.kt:m.t)+' +'+m.xp+' XP');}}
  });
}
function missionsHtml(){
  var ms=currentMissions();if(!ms.length)return'';
  var ch=CHALLENGES[dailyIndex(CHALLENGES.length,'c')],chDone=state.chDone===today();
  var chRow='<button style="display:flex;width:100%;background:none;border:0;padding:0;margin:2px 0 10px;font-family:inherit;font-size:13px;color:var(--tx);cursor:pointer;text-align:left;align-items:baseline" onclick="doChallenge()">'+
    '<span>'+(chDone?'✅ ':'🏆 ')+'<span style="font-weight:600">Today:</span> '+ch[0]+'</span>'+
    '<span style="margin-left:auto;color:var(--forest);white-space:nowrap;padding-left:8px">'+(chDone?ch[1]+' XP ✓':'+'+ch[1]+' XP')+'</span></button>';
  var rows=ms.map(function(m){var d=Math.min(state.missions[m.id]||0,m.n);var pct=Math.round(d/m.n*100);
    return '<div style="margin:8px 0"><div style="display:flex;font-size:13px"><span>'+(d>=m.n?'✅ ':'')+((state.kid&&m.kt)?m.kt:m.t)+'</span><span style="margin-left:auto;color:var(--tx2)">'+d+'/'+m.n+'</span></div>'+
      '<div style="height:7px;background:var(--line);border-radius:6px;margin-top:4px;overflow:hidden"><div style="height:100%;width:'+pct+'%;background:var(--forest)"></div></div></div>';}).join('');
  return '<h2 class="sec">Missions</h2><div class="card">'+chRow+rows+'</div>';
}
function todayActionSlug(){
  var causeActs=[];CATS.forEach(function(c){if(state.causes.indexOf(c.slug)>=0)causeActs=causeActs.concat(c.acts)});
  var pool=causeActs.length?causeActs:Object.keys(ACTS);
  if(state.kid){var kp=pool.filter(isKidOk);if(kp.length)pool=kp;}
  var start=dailyIndex(pool.length,'a'),slug=pool[start],pick=null;
  for(var k=0;k<pool.length;k++){var cand=pool[(start+k)%pool.length];if(!state.done[cand]){pick=cand;break;}}
  if(!pick){ /* cause pool exhausted - borrow from the full catalog */
    var all=Object.keys(ACTS),s2=dailyIndex(all.length,'a');
    for(var j=0;j<all.length;j++){var c2=all[(s2+j)%all.length];if(!state.done[c2]){pick=c2;break;}}
  }
  return pick||slug;
}
function dailyIndex(len,salt){var d=today()+salt,h=0;for(var i=0;i<d.length;i++){h=(h*31+d.charCodeAt(i))>>>0;}return h%len;}
function iucnStyle(s){var m={CR:['#B3261E','Critically Endangered'],EN:['#D97706','Endangered'],VU:['#CA8A04','Vulnerable'],NT:['#65A30D','Near Threatened'],LC:['#16A34A','Least Concern']};return m[s]||null;}
function iucnHtml(s){var i=iucnStyle(s);if(!i)return'';return'<span class="iucn" style="color:'+i[0]+';background:'+i[0]+'22">'+i[1]+'</span>';}
function pips(n){var h='<span class="pips" aria-label="Difficulty '+['','easy','medium','high impact'][n]+'">';for(var i=0;i<3;i++)h+='<span class="pip'+(i<n?' on':'')+'"></span>';return h+' '+['','Easy','Medium','High impact'][n]+'</span>';}
function round(v){return v===Math.round(v)?v:Math.round(v*10)/10;}
function newsAge(ds){var n=daysBetween(ds,today());if(n<=0)return 'today';if(n===1)return 'yesterday';if(n<31)return n+'d ago';return ds;}

/* ---------------- impact graph (GitHub-style) ---------------- */
function longestStreak(){
  var days=Object.keys(state.log).filter(function(d){return state.log[d]>0}).sort();
  if(!days.length)return 0;var best=1,cur=1;
  for(var i=1;i<days.length;i++){
    var prev=new Date(days[i-1]),now=new Date(days[i]);
    if((now-prev)===86400000){cur++;best=Math.max(best,cur);}else{cur=1;}
  }
  return best;
}
function graphHtml(){
  var weeks=53, cells=weeks*7, end=new Date();
  var dow=end.getDay(); // align so last column ends today
  var start=new Date(end.getTime()-(cells-1-(6-dow))*86400000);
  var html='<div class="graphwrap" id="graphwrap"><div class="graph">';
  var d=new Date(start), active=0;
  for(var w=0;w<weeks;w++){
    html+='<div class="gcol">';
    for(var r=0;r<7;r++){
      var key=dkey(d);
      var c=state.log[key]||0; if(c>0)active++;
      var future=d>end;
      var bg=future?'transparent':(c===0?'var(--g0)':c===1?'var(--g1)':c===2?'var(--g2)':'var(--g3)');
      html+='<div class="gcell" title="'+key+': '+c+' action'+(c===1?'':'s')+'" style="background:'+bg+'"></div>';
      d=new Date(d.getTime()+86400000);
    }
    html+='</div>';
  }
  html+='</div></div>';
  var totalActive=Object.keys(state.log).filter(function(k){return state.log[k]>0}).length;
  html+='<div class="muted" style="margin-top:8px">'+totalActive+' active days · longest streak '+longestStreak()+' days'+
        ' <span style="float:right">Less <span class="gcell" style="display:inline-block;background:var(--g0);vertical-align:middle"></span>'+
        '<span class="gcell" style="display:inline-block;background:var(--g1);vertical-align:middle;margin:0 2px"></span>'+
        '<span class="gcell" style="display:inline-block;background:var(--g2);vertical-align:middle;margin-right:2px"></span>'+
        '<span class="gcell" style="display:inline-block;background:var(--g3);vertical-align:middle"></span> More</span></div>';
  return html;
}

