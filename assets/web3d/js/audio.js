// ============================================================================
// Lightweight procedural audio (Web Audio API) so the build needs no binary
// sound assets. Provides a soft ambient drone plus short SFX cues. Real Turkish
// music / ambience tracks can be dropped in later and triggered from here.
// ============================================================================

let ctx = null;
let ambientGain = null;
let enabled = true;

function ensure() {
  if (ctx) return ctx;
  try {
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    ambientGain = ctx.createGain();
    ambientGain.gain.value = 0.05;
    ambientGain.connect(ctx.destination);
    startAmbient();
  } catch (e) {
    enabled = false;
  }
  return ctx;
}

// A slow, calm two-oscillator pad evoking a distant ney/drone.
function startAmbient() {
  if (!ctx) return;
  [110, 164.81].forEach((freq, i) => {
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = freq;
    g.gain.value = i === 0 ? 0.6 : 0.35;
    const lfo = ctx.createOscillator();
    const lfoGain = ctx.createGain();
    lfo.frequency.value = 0.07 + i * 0.03;
    lfoGain.gain.value = 2.5;
    lfo.connect(lfoGain).connect(osc.frequency);
    osc.connect(g).connect(ambientGain);
    osc.start();
    lfo.start();
  });
}

function blip(freq, dur, type = 'sine', vol = 0.18) {
  if (!enabled) return;
  ensure();
  if (!ctx) return;
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, ctx.currentTime);
  g.gain.setValueAtTime(vol, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + dur);
  osc.connect(g).connect(ctx.destination);
  osc.start();
  osc.stop(ctx.currentTime + dur);
}

export const Audio = {
  unlock() { ensure(); if (ctx && ctx.state === 'suspended') ctx.resume(); },
  setEnabled(on) { enabled = on; if (ambientGain) ambientGain.gain.value = on ? 0.05 : 0; },
  coin() { blip(880, 0.12, 'triangle'); setTimeout(() => blip(1320, 0.1, 'triangle'), 60); },
  chest() { blip(523, 0.18, 'sine'); setTimeout(() => blip(784, 0.25, 'sine'), 90); },
  discover() { [523, 659, 784, 1046].forEach((f, i) => setTimeout(() => blip(f, 0.18, 'sine'), i * 110)); },
  levelup() { [659, 784, 988, 1318].forEach((f, i) => setTimeout(() => blip(f, 0.22, 'triangle', 0.22), i * 90)); },
  step() { blip(140, 0.05, 'sine', 0.06); },
  photo() { blip(1500, 0.05, 'square', 0.12); },
};
