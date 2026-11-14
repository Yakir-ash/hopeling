/* Hopeling homepage behaviour. No libraries, no trackers.
   Data arrives in window.HL (written by scripts/build-home.cjs from the
   app's own source files), so the page and the app cannot disagree. */
(function () {
  'use strict';
  var HL = window.HL, d = document;
  var $ = function (s, r) { return (r || d).querySelector(s); };
  var $$ = function (s, r) { return [].slice.call((r || d).querySelectorAll(s)); };
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  // preview flags (comma separated) are only ever set by the build's --preview switch
  var PRE = window.__PREVIEW || '', PF = PRE ? PRE.split(',') : [];
  var flag = function (t) { return PF.indexOf(t) >= 0; };
  var fval = function (k) { for (var i = 0; i < PF.length; i++) if (PF[i].indexOf(k + '=') === 0) return PF[i].slice(k.length + 1); return ''; };

  /* ---------- the sky is the visitor's own ---------- */
  var now = new Date(), hr = now.getHours() + now.getMinutes() / 60;
  var sky = (hr < 5 || hr >= 21) ? 'night' : hr < 8 ? 'dawn' : hr < 17 ? 'day' : 'dusk';
  if (fval('sky')) { sky = fval('sky'); hr = { night: 23, dawn: 6.2, day: 12, dusk: 19 }[sky]; }
  d.documentElement.setAttribute('data-sky', sky);
  var orb = $('#orb'), halo = $('#halo');
  if (orb) {
    var arc = sky === 'night' ? 0.8 : Math.sin(Math.PI * Math.min(1, Math.max(0, (hr - 5) / 16)));
    var oy = 300 + (1 - arc) * 175, ox = sky === 'night' ? 960 : 880 + (hr - 13) * 9;
    [orb, halo].forEach(function (c) { if (c) { c.setAttribute('cx', ox); c.setAttribute('cy', oy); } });
  }
  var note = $('#skynote');
  if (note) {
    var hh = ('0' + now.getHours()).slice(-2) + ':' + ('0' + now.getMinutes()).slice(-2);
    note.textContent = 'This is your own sky: ' + hh + ', ' + sky + '. The app keeps the real one too.';
  }

  /* ---------- who is visiting ---------- */
  var who = HL.who, lede = $('#lede'), c1 = $('#cta1'), c2 = $('#cta2');
  $$('.who .chip').forEach(function (b) {
    b.addEventListener('click', function () {
      $$('.who .chip').forEach(function (x) { x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); });
      var w = who[b.getAttribute('data-who')];
      lede.textContent = w.lede;
      c1.textContent = w.c1[0]; c1.setAttribute('href', w.c1[1]);
      c2.textContent = w.c2[0]; c2.setAttribute('href', w.c2[1]);
    });
  });

  /* ---------- what the neighbours are doing this season ---------- */
  var ssn = ['winter', 'spring', 'summer', 'autumn'][Math.floor(((now.getMonth() + 1) % 12) / 3)];
  Object.keys(HL.near || {}).forEach(function (id) {
    var el = $('#near-' + id); if (el && HL.near[id].now[ssn]) el.textContent = HL.near[id].now[ssn];
  });
  var nw = $('#near-when'); if (nw) nw.textContent = 'This ' + ssn;

  /* ---------- reveal on scroll ---------- */
  var revs = $$('.rev');
  if (reduce || !('IntersectionObserver' in window) || PRE) revs.forEach(function (e) { e.classList.add('on'); });
  else {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('on'); io.unobserve(e.target); } });
    }, { threshold: 0.14 });
    revs.forEach(function (e) { io.observe(e); });
  }

  /* ---------- the model: the same equations as the app's Lab ---------- */
  var L = HL.lab, N = L.nodes, E = L.edges;
  var clamp = function (v) { return v < 0.02 ? 0.02 : (v > 1 ? 1 : v); };
  function runOnce(dg, band, from, drag, steps) {
    var x = from ? from.slice() : N.map(function (n) { return n.init; });
    var out = N.map(function () { return []; });
    for (var s = 0; s < steps; s++) {
      for (var i = 0; i < N.length; i++) out[i].push(x[i]);
      var nx = x.slice();
      for (i = 0; i < N.length; i++) {
        var n = N[i], g = n.g + band * (n.id === L.driven ? dg : 0);
        if (g > 0) g *= drag;
        var dx = g * x[i] * (1 - x[i]) + n.s * x[i];
        for (var e = 0; e < E.length; e++) {
          if (E[e][1] === n.id) {
            var fi = 0; while (N[fi].id !== E[e][0]) fi++;
            dx += band * E[e][2] * x[fi] * x[i];
          }
        }
        nx[i] = clamp(x[i] + dx);
      }
      x = nx;
    }
    return out;
  }
  var last = function (run) { return run.map(function (a) { return a[a.length - 1]; }); };
  function bands(dg, from, drag, steps) {
    return {
      lo: runOnce(dg, 0.8, from && last(from.lo), drag, steps),
      mid: runOnce(dg, 1.0, from && last(from.mid), drag, steps),
      hi: runOnce(dg, 1.2, from && last(from.hi), drag, steps)
    };
  }
  HL.__model = { runOnce: runOnce, bands: bands };

  /* ---------- the two benches ---------- */
  var lab = $('#bench');
  if (lab) {
    var lever = 1, guess = null, phase = 'idle', raf = 0;
    var A = bands(L.stay, null, 1, L.steps), A2 = runOnce(L.stay, 1, null, 1, L.steps * 2 - 1), B, R;
    var seasons = ['spring', 'summer', 'autumn', 'winter'];
    var off = Math.floor(((now.getMonth() + 10) % 12) / 3); // Mar-May = spring
    var whenEl = $('#when'), barEl = $('#bar'), said = $('#said'), verdict = $('#verdict');
    var pre = $('#stage-pre'), post = $('#stage-post'), runBtn = $('#run'), repBtn = $('#repair'), againBtn = $('#again');

    var show = function (bench, kind, n) {
      $$('#plot-' + bench + ' .' + kind).forEach(function (el, i) { el.classList.toggle('off', i >= n); });
    };
    var paint = function (bench, vals, bees) {
      show(bench, 'fl', Math.round(vals[0] * L.slots.f));
      show(bench, 'rb', Math.round(vals[1] * L.slots.r));
      show(bench, 'fx', Math.round(vals[2] * L.slots.x));
      show(bench, 'be', bees);
    };
    var at = function (run, k) { return run.map(function (a) { return a[Math.min(k, a.length - 1)]; }); };
    var label = function (k) { return seasons[(k + off) % 4] + ', year ' + (Math.floor(k / 4) + 1); };

    // sparklines: bench A dashed, bench B with its honest band
    var SW = 220, SH = 92, PADY = 8;
    var px = function (i, total) { return (i / (total - 1)) * SW; };
    var py = function (v) { return PADY + (1 - v) * (SH - 2 * PADY); };
    var line = function (arr, total) { return arr.map(function (v, i) { return (i ? 'L' : 'M') + px(i, total).toFixed(1) + ' ' + py(v).toFixed(1); }).join(''); };
    function drawSparks(total, bmid, blo, bhi, aref) {
      L.names.forEach(function (nm, i) {
        var up = bhi[i].map(function (v, k) { return px(k, total).toFixed(1) + ',' + py(v).toFixed(1); });
        var dn = blo[i].map(function (v, k) { return px(k, total).toFixed(1) + ',' + py(v).toFixed(1); }).reverse();
        var col = L.colors[i];
        $('#spark' + i).innerHTML =
          '<defs><clipPath id="cl' + i + '"><rect id="clr' + i + '" x="0" y="0" width="0" height="' + SH + '"/></clipPath></defs>' +
          (total > L.steps ? '<line x1="' + px(L.steps - 1, total).toFixed(1) + '" y1="2" x2="' + px(L.steps - 1, total).toFixed(1) + '" y2="' + (SH - 2) + '" stroke="#16241C" stroke-opacity=".18" stroke-dasharray="2 4"/>' : '') +
          '<g clip-path="url(#cl' + i + ')">' +
          '<polygon points="' + up.concat(dn).join(' ') + '" fill="' + col + '" fill-opacity=".17"/>' +
          '<path d="' + line(aref[i], total) + '" fill="none" stroke="#16241C" stroke-opacity=".42" stroke-width="2" stroke-dasharray="5 5"/>' +
          '<path d="' + line(bmid[i], total) + '" fill="none" stroke="' + col + '" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>' +
          '</g>';
      });
    }
    var clip = function (frac) { L.names.forEach(function (_, i) { var r = $('#clr' + i); if (r) r.setAttribute('width', (frac * SW + 2).toFixed(1)); }); };
    var ends = function (a, b) { L.names.forEach(function (_, i) { $('#end' + i).textContent = Math.round(a[i] * 100) + ' with the bees, ' + Math.round(b[i] * 100) + ' without'; }); };

    function reset() {
      cancelAnimationFrame(raf); phase = 'idle'; guess = null;
      B = bands(L.levers[lever].dg, null, 1, L.steps);
      paint('a', at(A.mid, 0), L.slots.b); paint('b', at(B.mid, 0), L.slots.b);
      $$('.patch').forEach(function (p) { p.classList.remove('on'); });
      $('#tag-b').textContent = L.levers[lever].label;
      $$('#guess .chip').forEach(function (c) { c.setAttribute('aria-pressed', 'false'); });
      runBtn.disabled = true; pre.hidden = false; post.hidden = true; repBtn.hidden = true; againBtn.hidden = true;
      barEl.style.width = '0'; whenEl.textContent = label(0);
      said.textContent = ''; verdict.textContent = '';
    }

    function play(total, fromK, onStep, onEnd) {
      if (reduce || PRE) { // no animation asked for: land on the result at once
        for (var kk = fromK; kk <= total - 1; kk++) onStep(kk);
        clip(1); barEl.style.width = '100%'; onEnd(); return;
      }
      var dur = (total - 1 - fromK) * 780, t0 = null;
      var lastK = -1;
      var tick = function (ts) {
        if (t0 === null) t0 = ts;
        var p = Math.min(1, (ts - t0) / dur), t = fromK + p * (total - 1 - fromK), k = Math.floor(t + 1e-6);
        if (k !== lastK) { lastK = k; onStep(k); }
        clip(t / (total - 1)); barEl.style.width = (p * 100).toFixed(1) + '%';
        if (p < 1) raf = requestAnimationFrame(tick); else onEnd();
      };
      raf = requestAnimationFrame(tick);
    }

    function start() {
      if (!guess) return;
      phase = 'running'; pre.hidden = true; post.hidden = false;
      var lv = L.levers[lever];
      drawSparks(L.steps, B.mid, B.lo, B.hi, A.mid);
      L.names.forEach(function (_, i) { $('#end' + i).textContent = ''; });
      play(L.steps, 0, function (k) {
        paint('a', at(A.mid, k), L.slots.b);
        paint('b', at(B.mid, k), k === 0 ? L.slots.b : lv.bees);
        whenEl.textContent = label(k);
        for (var m = lv.moments.length - 1; m >= 0; m--) if (lv.moments[m][0] <= k) { said.textContent = lv.moments[m][1]; break; }
      }, function () {
        phase = 'done';
        var a = last(A.mid), b = last(B.mid), fa = Math.round(a[2] * 100), fb = Math.round(b[2] * 100);
        var model = b[2] - a[2] > 0.03 ? 'higher' : (b[2] - a[2] < -0.03 ? 'lower' : 'about the same');
        ends(a, b);
        said.textContent = lv.epi;
        verdict.textContent = (guess === model
          ? 'You said ' + guess + '. So does the model: the foxes finish near ' + fb + ', against ' + fa + ' in the meadow that kept its bees. Now the interesting question is why. No fox ever met a bee.'
          : 'You said ' + guess + '. The model says ' + model + ': the foxes finish near ' + fb + ', against ' + fa + ' with the bees. That is the best place to be standing. Somewhere in the web is a thread you and the model read differently.');
        repBtn.hidden = false; againBtn.hidden = false;
      });
    }

    function repair() {
      phase = 'repairing'; repBtn.hidden = true;
      R = bands(L.repair.dg, B, L.repair.drag, L.steps);            // the app's own repair run: twelve points from the end state
      var cat = function (b, r) { return b.map(function (arr, i) { return arr.concat(r[i].slice(1)); }); };
      var total = L.steps * 2 - 1, mid = cat(B.mid, R.mid);
      drawSparks(total, mid, cat(B.lo, R.lo), cat(B.hi, R.hi), A2);
      clip((L.steps - 1) / (total - 1));
      $$('.patch').forEach(function (p) { p.classList.add('on'); });
      verdict.textContent = '';
      play(total, L.steps - 1, function (k) {
        paint('a', at(A2, k), L.slots.b);
        paint('b', at(mid, k), Math.max(L.levers[lever].bees, k > L.steps + 1 ? 2 : 1));
        whenEl.textContent = label(k);
        var rk = k - (L.steps - 1);
        for (var m = L.repair.moments.length - 1; m >= 0; m--) if (L.repair.moments[m][0] <= rk) { said.textContent = L.repair.moments[m][1]; break; }
      }, function () {
        phase = 'repaired';
        var f0 = Math.round(L.nodes[0].init * 100), f1 = Math.round(last(B.mid)[0] * 100), f2 = Math.round(mid[0][total - 1] * 100);
        said.textContent = L.repair.epi;
        verdict.textContent = 'Nearly three more years of care, and the flowers have climbed from ' + f1 + ' to ' + f2 + '. They began at ' + f0 + '. Recovery is real, and it is slower than never losing.';
        L.names.forEach(function (_, i) { $('#end' + i).textContent = 'now ' + Math.round(mid[i][total - 1] * 100) + ', after the repair'; });
      });
    }

    $$('#levers .chip').forEach(function (c, i) {
      c.addEventListener('click', function () {
        lever = i;
        $$('#levers .chip').forEach(function (x, j) { x.setAttribute('aria-pressed', j === i ? 'true' : 'false'); });
        reset();
      });
    });
    $$('#guess .chip').forEach(function (c) {
      c.addEventListener('click', function () {
        guess = c.getAttribute('data-g');
        $$('#guess .chip').forEach(function (x) { x.setAttribute('aria-pressed', x === c ? 'true' : 'false'); });
        runBtn.disabled = false;
      });
    });
    runBtn.addEventListener('click', start);
    repBtn.addEventListener('click', repair);
    againBtn.addEventListener('click', reset);
    reset();
    if (flag('lab-done') || flag('lab-repaired')) {
      guess = 'higher'; start();
      if (flag('lab-repaired')) repair();
    }
  }

  /* ---------- the little meadow ---------- */
  var mead = $('#meadow');
  if (mead) {
    var K = HL.kids, planted = 0, spots = $$('.spot', mead), story = $('#story'), count = $('#seedcount'), hear = $('#hear');
    var grow = function () {
      $$('#meadow .late').forEach(function (el, i) {
        setTimeout(function () { el.classList.remove('off'); }, reduce || PRE ? 0 : 140 * i);
      });
      story.textContent = K.growing;
      setTimeout(function () { story.textContent = K.closing; if (hear) hear.hidden = false; }, reduce || PRE ? 0 : 3600);
      count.textContent = 'This is the Little Meadow from Hopeling Kids, with the same model underneath as the one above.';
    };
    spots.forEach(function (s, i) {
      s.addEventListener('click', function () {
        if (s.classList.contains('done')) return;
        s.classList.add('done'); s.setAttribute('aria-label', 'A seed is planted here'); s.disabled = true;
        var sp = $('#sprout' + i); if (sp) sp.classList.remove('off');
        planted++;
        count.textContent = planted + ' of ' + spots.length + ' seeds in the ground';
        if (planted === spots.length) grow();
      });
    });
    if (hear && K.audio && K.audio.length) {
      hear.addEventListener('click', function () {
        var i = 0, a = new Audio();
        var next = function () { if (i >= K.audio.length) return; a.src = K.audio[i++]; a.play().catch(function () {}); };
        a.addEventListener('ended', next); next();
      });
    }
    if (flag('kids-done')) spots.forEach(function (s) { s.click(); });
  }

  /* ---------- the rain: the real count, only if it answers ---------- */
  var pulse = $('#pulse');
  if (pulse && window.fetch && !PRE) {
    fetch(HL.pulse.url, { headers: { apikey: HL.pulse.key } })
      .then(function (r) { return r.json(); })
      .then(function (rows) {
        var n = rows && rows.length ? rows[0].actions : null;
        if (!n) return;
        $('#pulse-n').textContent = Number(n).toLocaleString('en-US');
        pulse.hidden = false;
      }).catch(function () {});
  }

  /* ---------- goals: counted only if a privacy-first counter is installed ---------- */
  d.addEventListener('click', function (e) {
    var g = e.target.closest && e.target.closest('[data-goal]');
    if (g && window.goatcounter && window.goatcounter.count) {
      window.goatcounter.count({ path: 'goal-' + g.getAttribute('data-goal'), title: g.textContent.trim().slice(0, 60), event: true });
    }
  });

  if (fval('scroll')) {
    var t = $(fval('scroll'));
    if (t) setTimeout(function () { d.documentElement.style.scrollBehavior = 'auto'; window.scrollTo(0, t.getBoundingClientRect().top + window.pageYOffset - (+fval('dy') || 0)); }, 80);
  }
})();
