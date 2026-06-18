// ============================================================================
// Audio system.
//
//  1) REAL TRACKS — drop .mp3/.ogg files into assets/web3d/audio/ with the
//     names in TRACK_MANIFEST and they become the background music (looped,
//     per-district). This is the hook point for licensed Turkish music.
//  2) PROCEDURAL FALLBACK — if a track file is missing, a Turkish-flavoured
//     "makam" soundtrack is synthesised live (Web Audio): a drone + ney-like
//     lead + oud-like plucks over a Hijaz-ish scale. So audio always plays.
//  3) SFX — short synthesised cues for coins, chests, discovery, level-up, etc.
//  4) Weather bed — a procedural rain layer toggled with the weather.
// ============================================================================

export const TRACK_MANIFEST = {
  default: './audio/istanbul_theme.mp3',
  Sultanahmet: './audio/ottoman.mp3',
  'Eminönü': './audio/bazaar.mp3',
  'Beyoğlu': './audio/pera.mp3',
  Bosphorus: './audio/bosphorus.mp3',
  'Beşiktaş': './audio/bosphorus.mp3',
};

let ctx = null;
let musicGain = null, sfxGain = null, rainGain = null;
let enabled = true;
let started = false;

// makam (Hijaz-ish on D): D Eb F# G A Bb C — gives the recognisable flavour.
const SCALE = [293.66, 311.13, 369.99, 392.0, 440.0, 466.16, 523.25];
const PHRASE = [0, 1, 2, 1, 0, 2, 3, 2, 4, 3, 2, 1, 0, 0];
let phraseStep = 0;
let makamTimer = null;
let makamOn = false;
let currentTrackEl = null;

function ensure() {
  if (ctx) return ctx;
  try {
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    musicGain = ctx.createGain(); musicGain.gain.value = 0.16; musicGain.connect(ctx.destination);
    sfxGain = ctx.createGain(); sfxGain.gain.value = 0.3; sfxGain.connect(ctx.destination);
    rainGain = ctx.createGain(); rainGain.gain.value = 0.0; rainGain.connect(ctx.destination);
    buildRainBed();
  } catch (e) { enabled = false; }
  return ctx;
}

// ---- procedural makam soundtrack ----
function startMakam() {
  if (!ctx || makamOn) return;
  makamOn = true;
  // sustained drone (root + fifth)
  [146.83, 220.0].forEach((f, i) => {
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.value = f;
    g.gain.value = i === 0 ? 0.05 : 0.03;
    const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 600;
    osc.connect(lp).connect(g).connect(musicGain);
    osc.start();
  });
  // melodic phrase
  makamTimer = setInterval(() => {
    if (!enabled) return;
    const note = SCALE[PHRASE[phraseStep % PHRASE.length]];
    phraseStep++;
    pluck(note, 0.45, musicGain, 0.10);                 // oud-like
    if (phraseStep % 4 === 0) ney(note * 2, 0.9);       // ney-like answer
  }, 430);
}

function stopMakam() {
  makamOn = false;
  if (makamTimer) { clearInterval(makamTimer); makamTimer = null; }
}

function pluck(freq, dur, dest, vol) {
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = 'triangle';
  osc.frequency.value = freq;
  g.gain.setValueAtTime(vol, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
  osc.connect(g).connect(dest);
  osc.start();
  osc.stop(ctx.currentTime + dur);
}

function ney(freq, dur) {
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  const vib = ctx.createOscillator(); const vibG = ctx.createGain();
  osc.type = 'sine'; osc.frequency.value = freq;
  vib.frequency.value = 5.5; vibG.gain.value = 4; vib.connect(vibG).connect(osc.frequency);
  g.gain.setValueAtTime(0.0001, ctx.currentTime);
  g.gain.linearRampToValueAtTime(0.07, ctx.currentTime + 0.15);
  g.gain.linearRampToValueAtTime(0.0001, ctx.currentTime + dur);
  osc.connect(g).connect(musicGain);
  osc.start(); vib.start();
  osc.stop(ctx.currentTime + dur); vib.stop(ctx.currentTime + dur);
}

// ---- procedural rain bed (filtered noise) ----
function buildRainBed() {
  const len = 2 * ctx.sampleRate;
  const buf = ctx.createBuffer(1, len, ctx.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
  const src = ctx.createBufferSource();
  src.buffer = buf; src.loop = true;
  const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 2400;
  src.connect(lp).connect(rainGain);
  src.start();
}

// ---- real track loader (with fallback to makam) ----
function playTrack(url) {
  try {
    const el = new window.Audio(url);
    el.loop = true; el.volume = 0.5;
    let settled = false;
    el.addEventListener('canplaythrough', () => {
      settled = true;
      stopMakam();
      if (currentTrackEl && currentTrackEl !== el) currentTrackEl.pause();
      currentTrackEl = el;
      if (enabled) el.play().catch(() => startMakam());
    }, { once: true });
    el.addEventListener('error', () => { if (!settled) startMakam(); }, { once: true });
    // safety: if it never loads, fall back shortly
    setTimeout(() => { if (!settled) startMakam(); }, 1500);
  } catch (e) {
    startMakam();
  }
}

function sfx(freq, dur, type = 'sine', vol = 0.18) {
  if (!enabled) return;
  ensure(); if (!ctx) return;
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, ctx.currentTime);
  g.gain.setValueAtTime(vol, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
  osc.connect(g).connect(sfxGain);
  osc.start();
  osc.stop(ctx.currentTime + dur);
}

export const Audio = {
  unlock() {
    ensure();
    if (!ctx) return;
    if (ctx.state === 'suspended') ctx.resume();
    if (!started) { started = true; this.playMusic('default'); }
  },
  // Pick a real district track if present, otherwise procedural makam.
  playMusic(district) {
    ensure(); if (!ctx) return;
    const url = TRACK_MANIFEST[district] || TRACK_MANIFEST.default;
    playTrack(url);
  },
  setEnabled(on) {
    enabled = on;
    if (musicGain) musicGain.gain.value = on ? 0.16 : 0;
    if (sfxGain) sfxGain.gain.value = on ? 0.3 : 0;
    if (currentTrackEl) { on ? currentTrackEl.play().catch(() => {}) : currentTrackEl.pause(); }
  },
  setWeather(w) {
    if (!rainGain || !ctx) return;
    const target = (w === 'rain') ? 0.12 : 0.0;
    rainGain.gain.setTargetAtTime(target, ctx.currentTime, 0.6);
  },
  coin() { sfx(880, 0.12, 'triangle'); setTimeout(() => sfx(1320, 0.1, 'triangle'), 60); },
  chest() { sfx(523, 0.18, 'sine'); setTimeout(() => sfx(784, 0.25, 'sine'), 90); },
  discover() { [523, 659, 784, 1046].forEach((f, i) => setTimeout(() => sfx(f, 0.18, 'sine'), i * 110)); },
  levelup() { [659, 784, 988, 1318].forEach((f, i) => setTimeout(() => sfx(f, 0.22, 'triangle', 0.22), i * 90)); },
  step() { sfx(140, 0.05, 'sine', 0.06); },
  photo() { sfx(1500, 0.05, 'square', 0.12); },
};
