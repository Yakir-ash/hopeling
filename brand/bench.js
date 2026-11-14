/* The Classroom Bench in the browser. No libraries, no storage, no network:
   close the tab and the room's hands are gone. The lesson (window.BX) is
   written into the page by scripts/build-bench.cjs from the app's own
   lab.dart and bench.dart, so this page and the app teach the same thing. */
(function () {
  'use strict';
  var X = window.BX, d = document;
  var $ = function (s, r) { return (r || d).querySelector(s); };
  var $$ = function (s, r) { return [].slice.call((r || d).querySelectorAll(s)); };
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  var PF = (window.__PREVIEW || '').split(',');
  var fval = function (k) { for (var i = 0; i < PF.length; i++) if (PF[i].indexOf(k + '=') === 0) return PF[i].slice(k.length + 1); return ''; };
  var still = reduce || !!window.__PREVIEW;

  /* ---------- the model: the same equations as the app's Lab ---------- */
  var N = X.nodes, E = X.edges, STEPS = X.steps;
  var clamp = function (v) { return v < 0.02 ? 0.02 : (v > 1 ? 1 : v); };
  function runOnce(dg, band, from, drag, steps) {
    var x = from ? from.slice() : N.map(function (n) { return n.init; });
    var out = N.map(function () { return []; });
    for (var s = 0; s < steps; s++) {
      for (var i = 0; i < N.length; i++) out[i].push(x[i]);
      var nx = x.slice();
      for (i = 0; i < N.length; i++) {
        var n = N[i], g = n.g + band * (n.id === X.driven ? dg : 0);
        if (g > 0) g *= drag;
        var dx = g * x[i] * (1 - x[i]) + n.s * x[i];
        for (var e = 0; e < E.length; e++) if (E[e][1] === n.id) {
          var fi = 0; while (N[fi].id !== E[e][0]) fi++;
          dx += band * E[e][2] * x[fi] * x[i];
        }
        nx[i] = clamp(x[i] + dx);
      }
      x = nx;
    }
    return out;
  }
  var last = function (run) { return run.map(function (a) { return a[a.length - 1]; }); };
  var RUN = X.options.map(function (o) {
    return { lo: runOnce(o.dg, 0.8, null, 1, STEPS), mid: runOnce(o.dg, 1, null, 1, STEPS), hi: runOnce(o.dg, 1.2, null, 1, STEPS) };
  });
  var FI = X.focus.index, ASK = X.lesson.ask, ANS = ['higher', 'lower', 'about the same'];
  var gap = last(RUN[ASK].mid)[FI] - last(RUN[0].mid)[FI];
  var MODEL = gap > 0.03 ? 'higher' : (gap < -0.03 ? 'lower' : 'about the same');     // bench.dart: benchVerdict
  var direction = function (a) { return a[a.length - 1] > a[0] + 0.05 ? 'rises' : (a[a.length - 1] < a[0] - 0.05 ? 'falls' : 'holds'); };
  window.__bench = { RUN: RUN, MODEL: MODEL };

  /* ---------- the lesson's state: all of it lives here, and nowhere else ---------- */
  var STAGES = ['brief', 'hands', 'run', 'compare', 'discuss', 'close'];
  var stage = 0, card = 0, hands, repaired, t = 0, playing = false, raf = 0, lastTs = 0;
  var total = function () { return ANS.reduce(function (a, k) { return a + hands[k]; }, 0); };

  // bench.dart: roomVerdict, word for word
  function roomVerdict() {
    var f = X.focus.name, n = total();
    if (n === 0) return 'No hands counted, which is a fine way to run it too. The model says ' + f + ': ' + MODEL + '. Ask the room whether that is what they had assumed, before they saw it.';
    var top = ANS[0]; ANS.forEach(function (k) { if (hands[k] > hands[top]) top = k; });
    var tied = ANS.filter(function (k) { return hands[k] === hands[top]; }).length > 1;
    if (tied) return 'The room split evenly, and the model says ' + f + ': ' + MODEL + '. Keep both sentences alive in the room: a class that agrees too early stops looking.';
    if (top === MODEL) return 'Most of the room read the web the way the model does (' + f + ': ' + MODEL + '). Which means the interesting work is still ahead of you: they now have to say WHY, and "because I guessed it" is not a why.';
    return 'The room said ' + f + ': ' + top + '. The model says ' + f + ': ' + MODEL + '. This is the best place a lesson can begin: somewhere in the web below is one thread the room and the model read differently, and finding it is the whole lesson.';
  }

  /* ---------- drawing ---------- */
  var show = function (i, kind, n) { $$('#plot-' + i + ' .' + kind).forEach(function (el, j) { el.classList.toggle('off', j >= n); }); };
  function paint(k) {
    X.options.forEach(function (o, i) {
      var v = RUN[i].mid.map(function (a) { return a[Math.min(k, a.length - 1)]; });
      show(i, 'fl', Math.round(v[0] * X.slots.f)); show(i, 'rb', Math.round(v[1] * X.slots.r)); show(i, 'fx', Math.round(v[2] * X.slots.x));
      show(i, 'be', k === 0 ? X.slots.b : o.bees);
      v.forEach(function (val, j) { $('#ro-' + i + '-' + j).textContent = Math.round(val * 100); });
    });
    $('#when').textContent = 'season ' + (k + 1) + ' of ' + STEPS;
  }
  var path = function (arr, tot, w, h, pad) { return arr.map(function (v, i) { return (i ? 'L' : 'M') + ((i / (tot - 1)) * w).toFixed(1) + ' ' + (pad + (1 - v) * (h - 2 * pad)).toFixed(1); }).join(''); };
  var GCOL = ['#16241C', '#5E9B79', '#C8683A'];

  function renderHands() {
    ANS.forEach(function (k, i) { $('#n' + i).textContent = hands[k]; $('#add' + i).setAttribute('aria-label', X.focus.name + ', ' + k + '. ' + hands[k] + ' hands counted. Press to add one.'); });
    if (STAGES[stage] === 'hands') label();
  }
  function renderCompare() {
    var n = total();
    ANS.forEach(function (k, i) {
      $('#bar' + i).style.width = (n ? (hands[k] / n) * 100 : 0) + '%'; $('#bn' + i).textContent = hands[k];
      $('#barrow' + i).classList.toggle('model', k === MODEL);
    });
    $('#verdict').textContent = roomVerdict();
    X.options.forEach(function (o, i) {
      var a = RUN[i].mid[FI];
      $('#after' + i).textContent = X.focus.name + ': ' + direction(a) + ', ending near ' + Math.round(a[a.length - 1] * 100) + ' on the model\'s 0 to 100 scale.';
    });
    var W = 520, H = 190;
    $('#focuschart').innerHTML = X.options.map(function (o, i) {
      return '<path d="' + path(RUN[i].mid[FI], STEPS, W, H, 10) + '" fill="none" stroke="' + GCOL[i] + '" stroke-width="' + (i === ASK ? 4.5 : 3) + '" stroke-linecap="round" stroke-linejoin="round"' + (i === 0 ? ' stroke-dasharray="7 7"' : '') + '/>';
    }).join('');
  }
  function renderDiscuss() {
    var kinds = ['Notice', 'Explain', 'Carry it outside'];
    $('#qk').textContent = 'Question ' + (card + 1) + ' of ' + X.lesson.discuss.length + ' · ' + kinds[card % kinds.length];
    $('#qcard').textContent = X.lesson.discuss[card];
  }
  function renderClose() {
    $('#plant').hidden = repaired; $('#repaired').hidden = !repaired;
    if (!repaired) return;
    var o = X.options[ASK], B = RUN[ASK], R = {
      lo: runOnce(X.repair.dg, 0.8, last(B.lo), X.repair.drag, STEPS), mid: runOnce(X.repair.dg, 1, last(B.mid), X.repair.drag, STEPS), hi: runOnce(X.repair.dg, 1.2, last(B.hi), X.repair.drag, STEPS)
    };
    var cat = function (b, r) { return b.map(function (arr, i) { return arr.concat(r[i].slice(1)); }); };
    var mid = cat(B.mid, R.mid), lo = cat(B.lo, R.lo), hi = cat(B.hi, R.hi), tot = STEPS * 2 - 1, W = 220, H = 92, P = 8;
    X.names.forEach(function (nm, i) {
      var pt = function (arr) { return arr.map(function (v, k) { return ((k / (tot - 1)) * W).toFixed(1) + ',' + (P + (1 - v) * (H - 2 * P)).toFixed(1); }); };
      var xm = ((STEPS - 1) / (tot - 1)) * W;
      $('#spark' + i).innerHTML = '<line x1="' + xm.toFixed(1) + '" y1="2" x2="' + xm.toFixed(1) + '" y2="' + (H - 2) + '" stroke="#16241C" stroke-opacity=".2" stroke-dasharray="2 4"/>' +
        '<polygon points="' + pt(hi[i]).concat(pt(lo[i]).reverse()).join(' ') + '" fill="' + X.colors[i] + '" fill-opacity=".17"/>' +
        '<path d="' + path(mid[i], tot, W, H, P) + '" fill="none" stroke="' + X.colors[i] + '" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>';
      $('#end' + i).textContent = Math.round(B.mid[i][STEPS - 1] * 100) + ', then ' + Math.round(mid[i][tot - 1] * 100) + ' after the repair';
    });
    var f0 = Math.round(N[0].init * 100), f1 = Math.round(B.mid[0][STEPS - 1] * 100), f2 = Math.round(mid[0][tot - 1] * 100);
    $('#repairline').textContent = 'Under "' + o.label + '", nearly three more years of care bring the ' + X.names[0].toLowerCase() + ' from ' + f1 + ' back to ' + f2 + '. They began at ' + f0 + '.';
  }

  /* ---------- the clock: one for every bench ---------- */
  function stop() { playing = false; cancelAnimationFrame(raf); $('#play').textContent = '▶'; $('#play').setAttribute('aria-label', 'Play every bench together'); }
  function setT(v) { t = Math.max(0, Math.min(STEPS - 1, v)); $('#scrub').value = t; paint(Math.floor(t + 1e-6)); }
  function tick(ts) {
    if (!playing) return;
    if (!lastTs) lastTs = ts;
    setT(t + (ts - lastTs) / 820); lastTs = ts;
    if (t >= STEPS - 1) { stop(); return; }
    raf = requestAnimationFrame(tick);
  }
  function play() {
    if (still) { setT(STEPS - 1); return; }
    if (t >= STEPS - 1 - 1e-6) setT(0);
    playing = true; lastTs = 0; $('#play').textContent = '❚❚'; $('#play').setAttribute('aria-label', 'Pause every bench'); raf = requestAnimationFrame(tick);
  }

  /* ---------- moving through the lesson ---------- */
  var NEXT = { brief: 'Begin: the show of hands', run: 'Stop the clock and compare', compare: 'Open the discussion', close: 'Run it again with a fresh room' };
  function label() {
    var s = STAGES[stage];
    $('#next').textContent = s === 'hands' ? (total() ? 'Run all ' + X.options.length + ' benches at once' : 'Run it without counting')
      : s === 'discuss' ? (card < X.lesson.discuss.length - 1 ? 'Next question' : 'Close the lesson') : NEXT[s];
    $('#back').disabled = stage === 0;
  }
  function go(i) {
    stop(); stage = Math.max(0, Math.min(STAGES.length - 1, i));
    STAGES.forEach(function (s, j) {
      $('#s-' + s).hidden = j !== stage;
      var b = $('#rail' + j); b.classList.toggle('done', j < stage);
      if (j === stage) b.setAttribute('aria-current', 'step'); else b.removeAttribute('aria-current');
    });
    var s = STAGES[stage];
    if (s === 'hands') renderHands();
    if (s === 'run') { setT(0); play(); }
    if (s === 'compare') renderCompare();
    if (s === 'discuss') renderDiscuss();
    if (s === 'close') renderClose();
    label(); $('#main').scrollTop = 0;
    var h = $('#s-' + s + ' h1, #s-' + s + ' h2'); if (h) { h.setAttribute('tabindex', '-1'); h.focus({ preventScroll: true }); }
  }
  function reset() { hands = { higher: 0, lower: 0, 'about the same': 0 }; card = 0; repaired = false; t = 0; }
  function next() {
    var s = STAGES[stage];
    if (s === 'discuss' && card < X.lesson.discuss.length - 1) { card++; renderDiscuss(); label(); return; }
    if (s === 'close') { reset(); go(0); return; }
    go(stage + 1);
  }
  function back() {
    if (STAGES[stage] === 'discuss' && card > 0) { card--; renderDiscuss(); label(); return; }
    go(stage - 1);
  }

  $('#next').addEventListener('click', next);
  $('#back').addEventListener('click', back);
  STAGES.forEach(function (_, j) { $('#rail' + j).addEventListener('click', function () { go(j); }); });
  ANS.forEach(function (k, i) {
    $('#add' + i).addEventListener('click', function () { hands[k]++; renderHands(); });
    $('#less' + i).addEventListener('click', function () { if (hands[k] > 0) hands[k]--; renderHands(); });
  });
  $('#play').addEventListener('click', function () { if (playing) stop(); else play(); });
  $('#scrub').addEventListener('input', function () { stop(); setT(parseFloat(this.value)); });
  $('#plant').addEventListener('click', function () { repaired = true; renderClose(); });
  // a presenter's clicker sends Page Down and Page Up; so do the arrow keys
  d.addEventListener('keydown', function (e) {
    var tag = (e.target.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea' || e.altKey || e.ctrlKey || e.metaKey) return;
    if (e.key === 'ArrowRight' || e.key === 'PageDown') { e.preventDefault(); next(); }
    else if (e.key === 'ArrowLeft' || e.key === 'PageUp') { e.preventDefault(); if (stage > 0 || card > 0) back(); }
    else if (e.key === ' ' && STAGES[stage] === 'run' && tag !== 'button' && tag !== 'summary') { e.preventDefault(); if (playing) stop(); else play(); }
  });
  var fs = $('#fs'), root = d.documentElement;
  if (!root.requestFullscreen) fs.hidden = true;
  else {
    fs.addEventListener('click', function () { if (d.fullscreenElement) d.exitFullscreen(); else root.requestFullscreen().catch(function () {}); });
    d.addEventListener('fullscreenchange', function () { fs.textContent = d.fullscreenElement ? 'Leave full screen' : 'Full screen'; });
  }

  reset();
  if (fval('hands')) { var hv = fval('hands').split('-'); ANS.forEach(function (k, i) { hands[k] = +hv[i] || 0; }); }
  if (fval('card')) card = +fval('card');
  if (PF.indexOf('repaired') >= 0) repaired = true;
  go(+fval('stage') || 0);
})();
