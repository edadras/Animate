// ============================================================================
// Rahino: Istanbul Treasure Hunt — 3D engine (Three.js / WebGL)
// Rendered inside an embedded view; the Flutter shell draws the premium HUD on
// top and drives gameplay through the bridge (js/bridge.js).
// ============================================================================
import * as THREE from 'three';
import { Bridge } from './bridge.js';
import { Audio } from './audio.js';
import { preloadModels, hasModel, cloneStatic, instantiate, getAction, getActionByIndex } from './models.js';
import { WORLD, LANDMARKS, DISTRICTS, WEATHER } from './data.js';

let Sky = null; // loaded lazily; engine still runs if it fails

const statusEl = document.getElementById('engine-status');
function setStatus(t) { if (statusEl) statusEl.textContent = t; }

// ---------------------------------------------------------------------------
// Global engine state
// ---------------------------------------------------------------------------
const G = {
  scene: null, camera: null, renderer: null,
  clock: new THREE.Clock(),
  player: null, rahino: null,
  landmarks: [],          // {def, mesh, labelEl, discovered}
  coins: [], chests: [], npcs: [], vehicles: [], ferries: [], birds: [], pets: [],
  input: { x: 0, y: 0, run: false, jump: false },
  camYaw: 0, camDist: 11, camHeight: 5.5,
  time: 9.0,              // hours, 0..24
  timeScale: 1 / 90,      // game-hours per real-second (full day ~ 36 min)
  weather: 'sunny',
  paused: false,
  photoMode: false,
  waypoint: null,         // THREE.Vector3 or null
  waypointId: null,
  nearInteract: null,     // {type, ref, pos, label}
  sun: null, hemi: null, sky: null, skyUniforms: null,
  rainSys: null, snowSys: null,
  ready: false,
  density: 1,
  mixers: [],   // active AnimationMixers (from loaded .glb characters)
};

const TMP = new THREE.Vector3();
const UP = new THREE.Vector3(0, 1, 0);

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------
init().catch((e) => {
  console.error(e);
  setStatus('3D failed to start: ' + e.message);
  Bridge.emit('error', { message: String(e && e.message || e) });
});

async function init() {
  setStatus('Loading 3D engine…');
  try { ({ Sky } = await import('three/addons/objects/Sky.js')); } catch { Sky = null; }

  const canvas = document.getElementById('scene');
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  G.renderer = renderer;

  const scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(0xbcd3e6, 0.0016);
  G.scene = scene;

  const camera = new THREE.PerspectiveCamera(58, window.innerWidth / window.innerHeight, 0.1, 4000);
  camera.position.set(0, 8, 16);
  G.camera = camera;

  buildLighting();
  buildSky();
  buildGround();
  buildWater();
  buildRoads();

  setStatus('Loading 3D models…');
  const modelsLoaded = await preloadModels();
  setStatus(modelsLoaded ? `Loaded ${modelsLoaded} 3D models…` : 'Building world…');

  buildLandmarks();
  buildVegetation();
  buildPlayer();
  buildRahino();
  spawnCoins(140);
  spawnChests(16);
  spawnNPCs(60);
  spawnVehicles(22);
  spawnFerries(5);
  spawnBirds(24);
  spawnPets(18);

  bindInput();
  bindCommands();
  window.addEventListener('resize', onResize);

  G.ready = true;
  updateSun();
  setStatus('');
  statusEl.classList.add('hidden');
  Bridge.emit('ready', { landmarks: LANDMARKS.map((l) => l.id) });
  rahinoSay('Hoş geldin! Welcome to Istanbul! Follow the markers and let’s explore. 🧭');

  renderer.setAnimationLoop(loop);
}

// ---------------------------------------------------------------------------
// Lighting / Sky
// ---------------------------------------------------------------------------
function buildLighting() {
  const hemi = new THREE.HemisphereLight(0xcfe6ff, 0x5a5145, 0.7);
  G.scene.add(hemi); G.hemi = hemi;

  const sun = new THREE.DirectionalLight(0xfff2da, 2.4);
  sun.castShadow = true;
  sun.shadow.mapSize.set(2048, 2048);
  const s = 220;
  sun.shadow.camera.left = -s; sun.shadow.camera.right = s;
  sun.shadow.camera.top = s; sun.shadow.camera.bottom = -s;
  sun.shadow.camera.near = 1; sun.shadow.camera.far = 900;
  sun.shadow.bias = -0.0004;
  G.scene.add(sun);
  G.scene.add(sun.target);
  G.sun = sun;
}

function buildSky() {
  if (!Sky) { G.scene.background = new THREE.Color(0x9ec4e6); return; }
  const sky = new Sky();
  sky.scale.setScalar(20000);
  const u = sky.material.uniforms;
  u.turbidity.value = 6;
  u.rayleigh.value = 2.2;
  u.mieCoefficient.value = 0.005;
  u.mieDirectionalG.value = 0.8;
  G.scene.add(sky);
  G.sky = sky; G.skyUniforms = u;
}

// Update sun position, colors and sky from G.time + weather.
function updateSun() {
  const t = G.time;
  // elevation: peaks at noon, below horizon at night
  const dayPhase = Math.cos(((t - 13) / 24) * Math.PI * 2); // ~1 at 13:00
  const elevation = Math.max(-12, dayPhase * 62 - 6);
  const azimuth = ((t / 24) * 360 + 90) % 360;
  const phi = THREE.MathUtils.degToRad(90 - elevation);
  const theta = THREE.MathUtils.degToRad(azimuth);
  const dir = new THREE.Vector3().setFromSphericalCoords(1, phi, theta);

  G.sun.position.copy(dir).multiplyScalar(400);
  G.sun.target.position.copy(G.player ? G.player.position : new THREE.Vector3());

  const daylight = THREE.MathUtils.clamp((elevation + 6) / 50, 0, 1);
  let sunColor = new THREE.Color(0xfff2da);
  if (elevation < 12) sunColor = new THREE.Color(0xff9d5c); // golden/sunset
  G.sun.color.copy(sunColor);
  G.sun.intensity = 0.4 + daylight * 2.4;
  G.hemi.intensity = 0.25 + daylight * 0.7;

  // night tint
  const night = new THREE.Color(0x0b1830);
  const sky = new THREE.Color(0x9ec4e6);
  const bg = night.clone().lerp(sky, daylight);
  if (!G.sky) G.scene.background = bg;
  if (G.scene.fog) G.scene.fog.color.copy(bg.clone().lerp(new THREE.Color(0xffffff), 0.05));

  applyWeatherColors(daylight);

  if (G.skyUniforms) {
    G.skyUniforms.sunPosition.value.copy(dir);
    G.skyUniforms.rayleigh.value = G.weather === 'fog' ? 0.6 : (2.2 - (1 - daylight) * 1.4 + 0.001);
    G.skyUniforms.turbidity.value = G.weather === 'rain' ? 14 : (G.weather === 'fog' ? 18 : 6);
  }
}

function applyWeatherColors(daylight) {
  if (!G.scene.fog) return;
  const f = G.scene.fog;
  switch (G.weather) {
    case 'rain': f.density = 0.0042; f.color.setHex(0x6b7884); break;
    case 'fog':  f.density = 0.011;  f.color.setHex(0xc9d4dc); break;
    case 'snow': f.density = 0.0048; f.color.setHex(0xd7e1ea); break;
    case 'sunset': f.density = 0.0022; break;
    default:     f.density = 0.0016; break;
  }
}

// ---------------------------------------------------------------------------
// Ground / water / roads
// ---------------------------------------------------------------------------
function buildGround() {
  const geo = new THREE.PlaneGeometry(WORLD.size * 2, WORLD.size * 2, 64, 64);
  geo.rotateX(-Math.PI / 2);
  // gentle hills
  const pos = geo.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getZ(i);
    const d = Math.hypot(x, z);
    const h = Math.sin(x * 0.01) * 2 + Math.cos(z * 0.012) * 2 + Math.max(0, (d - 200) * 0.02);
    pos.setY(i, h);
  }
  geo.computeVertexNormals();
  const mat = new THREE.MeshStandardMaterial({ color: 0x6f8f63, roughness: 1, metalness: 0 });
  const ground = new THREE.Mesh(geo, mat);
  ground.receiveShadow = true;
  G.scene.add(ground);
}

function buildWater() {
  // Golden Horn + Bosphorus as one animated reflective plane band.
  const geo = new THREE.PlaneGeometry(900, 320, 80, 32);
  geo.rotateX(-Math.PI / 2);
  const mat = new THREE.MeshStandardMaterial({
    color: 0x2f6e9e, roughness: 0.22, metalness: 0.0, transparent: true, opacity: 0.9,
  });
  const water = new THREE.Mesh(geo, mat);
  water.position.set(60, 0.2, 0);
  water.rotation.y = -0.18;
  water.receiveShadow = false;
  G.scene.add(water);
  G.water = water;
  G.waterBase = geo.attributes.position.array.slice();
}

function animateWater(t) {
  if (!G.water) return;
  const pos = G.water.geometry.attributes.position;
  const base = G.waterBase;
  for (let i = 0; i < pos.count; i++) {
    const x = base[i * 3], z = base[i * 3 + 2];
    pos.setY(i, Math.sin(x * 0.05 + t * 1.4) * 0.35 + Math.cos(z * 0.07 + t * 1.1) * 0.3);
  }
  pos.needsUpdate = true;
}

function buildRoads() {
  const mat = new THREE.MeshStandardMaterial({ color: 0x3a3a40, roughness: 0.9 });
  // a few arterial roads connecting districts
  const roads = [
    [[-260, -210], [-40, -150]], [[-40, -150], [-15, -55]], [[-15, -55], [-5, 10]],
    [[-5, 10], [40, 150]], [[40, 150], [90, 175]], [[-5, 10], [120, -140]],
    [[120, -140], [200, 90]], [[40, 150], [240, 30]],
  ];
  for (const [a, b] of roads) {
    const ax = a[0], az = a[1], bx = b[0], bz = b[1];
    const len = Math.hypot(bx - ax, bz - az);
    const road = new THREE.Mesh(new THREE.PlaneGeometry(len, 9), mat);
    road.rotation.x = -Math.PI / 2;
    road.position.set((ax + bx) / 2, 0.06, (az + bz) / 2);
    road.rotation.z = -Math.atan2(bz - az, bx - ax);
    road.receiveShadow = true;
    G.scene.add(road);
  }
  G.roadPaths = roads;
}

// ---------------------------------------------------------------------------
// Landmarks (stylized architecture per type)
// ---------------------------------------------------------------------------
function buildLandmarks() {
  const labelRoot = document.getElementById('world-labels');
  for (const def of LANDMARKS) {
    const group = new THREE.Group();
    group.position.set(def.pos[0], 0, def.pos[1]);
    const accent = (DISTRICTS[def.district] || {}).accent || 0xcccccc;
    buildLandmarkMesh(group, def, accent);
    G.scene.add(group);

    const el = document.createElement('div');
    el.className = 'world-label far';
    el.innerHTML = `<span class="icon">${def.icon}</span><span>${def.name}</span>`;
    labelRoot.appendChild(el);

    G.landmarks.push({ def, mesh: group, labelEl: el, discovered: false, center: group.position.clone() });
  }
}

function mkMat(color, rough = 0.8, metal = 0.0) {
  return new THREE.MeshStandardMaterial({ color, roughness: rough, metalness: metal });
}

function buildLandmarkMesh(group, def, accent) {
  // Use a real building model for this landmark type when available.
  const modelBuilding = cloneStatic('building_' + def.type);
  if (modelBuilding) { group.add(modelBuilding); return; }

  const stone = mkMat(0xe7ddc7), accentMat = mkMat(accent), dome = mkMat(0xb9c4cf, 0.4, 0.2);
  const addShadow = (m) => { m.castShadow = true; m.receiveShadow = true; return m; };

  const base = (w, h, d, mat, y = 0) => {
    const m = addShadow(new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat));
    m.position.y = y + h / 2; group.add(m); return m;
  };
  const domeMesh = (r, y) => {
    const m = addShadow(new THREE.Mesh(new THREE.SphereGeometry(r, 24, 16, 0, Math.PI * 2, 0, Math.PI / 2), dome));
    m.position.y = y; group.add(m); return m;
  };
  const minaret = (x, z, h) => {
    const m = addShadow(new THREE.Mesh(new THREE.CylinderGeometry(0.7, 0.9, h, 12), stone));
    m.position.set(x, h / 2, z); group.add(m);
    const cap = addShadow(new THREE.Mesh(new THREE.ConeGeometry(0.9, 3, 12), accentMat));
    cap.position.set(x, h + 1.5, z); group.add(cap);
  };

  switch (def.type) {
    case 'monument': // mosques / Hagia Sophia / Ortaköy
      base(22, 14, 22, stone);
      domeMesh(11, 14);
      minaret(-13, -13, 30); minaret(13, -13, 30);
      minaret(-13, 13, 30); minaret(13, 13, 30);
      break;
    case 'tower': // Galata / Maiden's
      { const t = addShadow(new THREE.Mesh(new THREE.CylinderGeometry(7, 8, 34, 20), stone));
        t.position.y = 17; group.add(t);
        const cone = addShadow(new THREE.Mesh(new THREE.ConeGeometry(8.5, 12, 20), accentMat));
        cone.position.y = 40; group.add(cone); }
      break;
    case 'bridge':
      { const deck = addShadow(new THREE.Mesh(new THREE.BoxGeometry(120, 2, 14), mkMat(0x9a9a9a)));
        deck.position.y = 4; group.add(deck);
        for (let i = -3; i <= 3; i++) {
          const p = addShadow(new THREE.Mesh(new THREE.BoxGeometry(2, 8, 2), stone));
          p.position.set(i * 18, 0, 0); group.add(p);
        } }
      break;
    case 'market': case 'street':
      for (let i = 0; i < 10; i++) {
        const h = 8 + Math.random() * 8;
        const b = base(8 + Math.random() * 5, h, 8 + Math.random() * 5,
          mkMat(new THREE.Color().setHSL(0.08 + Math.random() * 0.05, 0.4, 0.6)));
        b.position.x = (i % 5) * 11 - 22; b.position.z = Math.floor(i / 5) * 12 - 6;
      }
      base(26, 5, 26, accentMat); // covered arcade roof
      break;
    case 'park': case 'viewpoint': case 'scenic': case 'hidden':
      base(6, 3, 6, accentMat); // small kiosk / marker
      for (let i = 0; i < 6; i++) tree(group, (Math.random() - 0.5) * 30, (Math.random() - 0.5) * 30);
      break;
    case 'transport': // airport / ferry / metro
      base(30, 9, 16, mkMat(0xcdd6dd, 0.4, 0.3));
      { const roof = addShadow(new THREE.Mesh(new THREE.BoxGeometry(34, 1.5, 20), accentMat));
        roof.position.y = 10; group.add(roof); }
      break;
    case 'hotel':
      for (let i = 0; i < 4; i++) base(14, 6, 12, mkMat(0xd8c9a8)).position.y = i * 6 + 3;
      base(14, 24, 12, mkMat(0xd8c9a8));
      break;
    case 'cafe': case 'restaurant':
      base(12, 6, 12, mkMat(0xc98f5a));
      { const awn = addShadow(new THREE.Mesh(new THREE.BoxGeometry(16, 0.6, 6), mkMat(0xc0392b)));
        awn.position.set(0, 6.3, 8); group.add(awn); }
      break;
    default:
      base(14, 12, 14, stone); domeMesh(7, 12);
  }
}

function tree(parent, x, z) {
  const model = cloneStatic('tree');
  if (model) { model.position.set(x, 0, z); model.rotation.y = Math.random() * Math.PI * 2; parent.add(model); return model; }
  const g = new THREE.Group();
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.7, 4, 7), mkMat(0x6b4a2b));
  trunk.position.y = 2; trunk.castShadow = true; g.add(trunk);
  const leaf = new THREE.Mesh(new THREE.SphereGeometry(3, 10, 8), mkMat(0x3f7d3a));
  leaf.position.y = 5.5; leaf.castShadow = true; g.add(leaf);
  g.position.set(x, 0, z); parent.add(g); return g;
}

function buildVegetation() {
  const parks = LANDMARKS.filter((l) => ['park', 'viewpoint', 'scenic'].includes(l.type));
  for (let i = 0; i < 120; i++) {
    const x = (Math.random() - 0.5) * WORLD.size * 1.6;
    const z = (Math.random() - 0.5) * WORLD.size * 1.6;
    if (Math.abs(z) < 70 && x > -200 && x < 250) continue; // keep water clear
    tree(G.scene, x, z);
  }
}

// ---------------------------------------------------------------------------
// Characters
// ---------------------------------------------------------------------------
function makeHumanoid(opts = {}) {
  const skin = opts.skin || 0xe7b48a;
  const shirt = opts.shirt || 0x3a6ea5;
  const pants = opts.pants || 0x2c3e50;
  const g = new THREE.Group();
  const mk = (geo, mat, y) => { const m = new THREE.Mesh(geo, mkMat(mat)); m.castShadow = true; m.position.y = y; return m; };

  const torso = mk(new THREE.CapsuleGeometry(0.55, 0.9, 4, 8), shirt, 1.6); g.add(torso);
  const head = mk(new THREE.SphereGeometry(0.45, 16, 12), skin, 2.7); g.add(head);
  const hair = mk(new THREE.SphereGeometry(0.47, 12, 8, 0, Math.PI * 2, 0, Math.PI / 2), opts.hair || 0x222018, 2.8); g.add(hair);

  const armL = mk(new THREE.CapsuleGeometry(0.16, 0.8, 4, 6), shirt, 1.6);
  const armR = armL.clone(); armL.position.set(0.72, 1.7, 0); armR.position.set(-0.72, 1.7, 0);
  const legL = mk(new THREE.CapsuleGeometry(0.2, 0.85, 4, 6), pants, 0.6);
  const legR = legL.clone(); legL.position.set(0.26, 0.7, 0); legR.position.set(-0.26, 0.7, 0);
  g.add(armL, armR, legL, legR);

  g.userData.parts = { armL, armR, legL, legR, head };
  return g;
}

// Build an animated character from a .glb if available, else procedural.
function makeAnimatedChar(modelId, proceduralOpts, modelScale) {
  const inst = instantiate(modelId);
  if (!inst) return makeHumanoid(proceduralOpts);
  const g = new THREE.Group();
  inst.root.scale.setScalar(modelScale || 1);
  g.add(inst.root);
  g.userData.model = true;
  g.userData.mixer = inst.mixer;
  if (inst.mixer) {
    const idle = getAction(inst, ['Idle', 'idle', 'IDLE']) || getActionByIndex(inst, 0);
    const walk = getAction(inst, ['Walk', 'walk', 'Walking']);
    const run = getAction(inst, ['Run', 'run', 'Running']);
    if (idle) idle.setEffectiveWeight(1);
    g.userData.actions = { idle, walk, run };
    G.mixers.push(inst.mixer);
  }
  return g;
}

function updateModelChar(char, speed, dt) {
  const a = char.userData.actions;
  if (!a) return;
  const moving = speed > 0.1, running = speed > 9;
  const lerp = (act, target) => { if (act) act.setEffectiveWeight(THREE.MathUtils.lerp(act.getEffectiveWeight(), target, Math.min(1, dt * 8))); };
  lerp(a.idle, moving ? 0 : 1);
  lerp(a.walk, moving && !running ? 1 : 0);
  lerp(a.run, running ? 1 : 0);
}

function animateChar(char, speed, dt) {
  if (char.userData.model) updateModelChar(char, speed, dt);
  else animateLimbs(char, speed, dt);
}

function buildPlayer() {
  const p = makeAnimatedChar('player', { shirt: 0x2e8b57, pants: 0x394b59, skin: 0xe8b48c }, 1.0);
  p.position.set(-256, groundHeight(-256, -200), -200); // start near airport
  G.scene.add(p);
  G.player = p;
  G.player.userData.vy = 0;
  G.player.userData.onGround = true;
  G.player.userData.speed = 0;
  G.player.userData.cosmetics = { outfit: null, backpack: null, pet: null };
}

// Rahino: friendly rhino mascot in a rainbow "Rahino" hoodie + backpack.
function buildRahino() {
  // Prefer a real .glb model when present.
  if (hasModel('rahino')) {
    const r = makeAnimatedChar('rahino', {}, 1.0);
    r.scale.setScalar(0.92);
    r.position.copy(G.player.position).add(new THREE.Vector3(2, 0, 2));
    G.scene.add(r);
    G.rahino = r;
    if (!r.userData.parts) r.userData.parts = { armL: new THREE.Object3D(), armR: new THREE.Object3D(), legL: new THREE.Object3D(), legR: new THREE.Object3D(), head: new THREE.Object3D() };
    r.userData.emote = null; r.userData.emoteT = 0; r.userData.bobT = 0;
    return;
  }
  const g = new THREE.Group();
  const mk = (geo, mat, y) => { const m = new THREE.Mesh(geo, mkMat(mat)); m.castShadow = true; m.position.y = y; return m; };

  const body = mk(new THREE.CapsuleGeometry(0.7, 0.7, 6, 12), 0xf3efe6, 1.4); g.add(body); // cream hoodie
  // rainbow stripe across hoodie
  const stripe = new THREE.Mesh(new THREE.TorusGeometry(0.72, 0.12, 8, 24, Math.PI),
    new THREE.MeshStandardMaterial({ color: 0xff5b5b }));
  stripe.position.set(0, 1.5, 0.1); stripe.rotation.x = Math.PI / 2; g.add(stripe);

  const head = mk(new THREE.SphereGeometry(0.62, 18, 14), 0xf3efe6, 2.55); head.scale.z = 1.25; g.add(head);
  const horn = mk(new THREE.ConeGeometry(0.16, 0.5, 10), 0xe6dccb, 3.0); horn.position.z = 0.6; horn.rotation.x = -0.5; g.add(horn);
  const earL = mk(new THREE.SphereGeometry(0.18, 8, 8), 0xf0c8c8, 3.05); earL.position.set(0.4, 3.05, -0.1);
  const earR = earL.clone(); earR.position.x = -0.4; g.add(earL, earR);

  const eyeGeo = new THREE.SphereGeometry(0.12, 10, 10);
  const eyeMat = new THREE.MeshStandardMaterial({ color: 0x2a6fb0 });
  const eyeL = new THREE.Mesh(eyeGeo, eyeMat); eyeL.position.set(0.22, 2.62, 0.62);
  const eyeR = eyeL.clone(); eyeR.position.x = -0.22; g.add(eyeL, eyeR);

  const armL = mk(new THREE.CapsuleGeometry(0.18, 0.5, 4, 6), 0xf3efe6, 1.45); armL.position.x = 0.78;
  const armR = armL.clone(); armR.position.x = -0.78; g.add(armL, armR);
  const legL = mk(new THREE.CapsuleGeometry(0.22, 0.4, 4, 6), 0x2c4a8a, 0.5); legL.position.x = 0.3;
  const legR = legL.clone(); legR.position.x = -0.3; g.add(legL, legR);

  // backpack
  const pack = mk(new THREE.BoxGeometry(0.8, 0.9, 0.4), 0xe23b3b, 1.5); pack.position.z = -0.6; g.add(pack);

  g.scale.setScalar(0.92);
  g.position.copy(G.player.position).add(new THREE.Vector3(2, 0, 2));
  G.scene.add(g);
  G.rahino = g;
  G.rahino.userData = { parts: { armL, armR, legL, legR, head }, emote: null, emoteT: 0, bobT: 0 };
}

// ---------------------------------------------------------------------------
// Collectibles & entities
// ---------------------------------------------------------------------------
function randPos(spread = WORLD.size) {
  return new THREE.Vector3((Math.random() - 0.5) * spread, 0, (Math.random() - 0.5) * spread);
}

function spawnCoins(n) {
  const geo = new THREE.CylinderGeometry(0.45, 0.45, 0.1, 18);
  const mat = new THREE.MeshStandardMaterial({ color: 0xffcc33, metalness: 0.3, roughness: 0.35, emissive: 0x6a4a00, emissiveIntensity: 0.5 });
  const useModel = hasModel('coin');
  for (let i = 0; i < n; i++) {
    const m = useModel ? cloneStatic('coin') : new THREE.Mesh(geo, mat);
    const p = randPos(WORLD.size * 1.4);
    if (Math.abs(p.z) < 60 && p.x > -200 && p.x < 240) p.z += 120; // off the water
    m.position.set(p.x, groundHeight(p.x, p.z) + 1.2, p.z);
    if (!useModel) m.rotation.x = Math.PI / 2;
    m.castShadow = true;
    G.scene.add(m);
    G.coins.push(m);
  }
}

function spawnChests(n) {
  for (let i = 0; i < n; i++) {
    const model = cloneStatic('chest');
    if (model) {
      const g = new THREE.Group();
      g.add(model);
      const p = randPos(WORLD.size * 1.3);
      g.position.set(p.x, groundHeight(p.x, p.z), p.z);
      g.userData = { opened: false, lid: model };
      G.scene.add(g);
      G.chests.push(g);
      continue;
    }
    const g = new THREE.Group();
    const box = new THREE.Mesh(new THREE.BoxGeometry(1.2, 0.8, 0.9), mkMat(0x7a4a22));
    const lid = new THREE.Mesh(new THREE.BoxGeometry(1.25, 0.35, 0.95), mkMat(0x5a3416));
    lid.position.y = 0.55; box.position.y = 0.4; box.castShadow = true; lid.castShadow = true;
    const band = new THREE.Mesh(new THREE.BoxGeometry(1.3, 0.9, 0.2), mkMat(0xd4af37, 0.4, 0.7));
    band.position.y = 0.4; g.add(box, lid, band);
    const p = randPos(WORLD.size * 1.3);
    g.position.set(p.x, groundHeight(p.x, p.z), p.z);
    g.userData = { opened: false, lid };
    G.scene.add(g);
    G.chests.push(g);
  }
}

const NPC_KINDS = ['Tourist', 'Hotel Staff', 'Taxi Driver', 'Restaurant Owner', 'Police', 'Airport Staff', 'Street Vendor', 'Boat Captain', 'Museum Guide'];
function spawnNPCs(n) {
  n = Math.round(n * G.density);
  for (let i = 0; i < n; i++) {
    const kind = NPC_KINDS[i % NPC_KINDS.length];
    const npc = cloneStatic('npc') || makeHumanoid({
      shirt: new THREE.Color().setHSL(Math.random(), 0.5, 0.5).getHex(),
      pants: new THREE.Color().setHSL(Math.random(), 0.3, 0.35).getHex(),
      skin: [0xe8b48c, 0xd49a6a, 0xc88a5a][i % 3],
    });
    npc.scale.setScalar(0.92);
    const p = randPos(WORLD.size * 1.2);
    npc.position.set(p.x, groundHeight(p.x, p.z), p.z);
    npc.userData = { kind, id: 'npc_' + i, phase: Math.random() * Math.PI * 2,
      origin: npc.position.clone(), heading: Math.random() * Math.PI * 2, speed: 0.6 + Math.random() };
    G.scene.add(npc);
    G.npcs.push(npc);
  }
}

function spawnVehicles(n) {
  for (let i = 0; i < n; i++) {
    const isBus = i % 4 === 0;
    const g = new THREE.Group();
    const model = cloneStatic(isBus ? 'bus' : 'car');
    if (model) {
      g.add(model);
    } else {
      const body = new THREE.Mesh(new THREE.BoxGeometry(isBus ? 6 : 3.2, isBus ? 2.4 : 1.4, isBus ? 2.4 : 1.6),
        mkMat(isBus ? 0xc0392b : new THREE.Color().setHSL(Math.random(), 0.6, 0.5).getHex(), 0.3, 0.4));
      body.position.y = isBus ? 1.6 : 1.0; body.castShadow = true; g.add(body);
    }
    const path = G.roadPaths[i % G.roadPaths.length];
    g.userData = { path, t: Math.random(), speed: (isBus ? 0.03 : 0.06) + Math.random() * 0.04, isBus };
    G.scene.add(g);
    G.vehicles.push(g);
  }
}

function spawnFerries(n) {
  for (let i = 0; i < n; i++) {
    const g = new THREE.Group();
    const model = cloneStatic('ferry');
    if (model) {
      g.add(model);
    } else {
      const hull = new THREE.Mesh(new THREE.BoxGeometry(10, 2.4, 4), mkMat(0xf5f5f5, 0.5));
      hull.position.y = 1.2; const deck = new THREE.Mesh(new THREE.BoxGeometry(7, 1.6, 3.4), mkMat(0xffd34e));
      deck.position.y = 2.8; const stack = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.5, 2, 10), mkMat(0xc0392b));
      stack.position.set(-1, 4, 0); hull.castShadow = true; g.add(hull, deck, stack);
    }
    g.userData = { t: Math.random(), speed: 0.02 + Math.random() * 0.02, radius: 120 + i * 18 };
    G.scene.add(g);
    G.ferries.push(g);
  }
}

function spawnBirds(n) {
  for (let i = 0; i < n; i++) {
    const m = new THREE.Mesh(new THREE.ConeGeometry(0.3, 1.2, 4), mkMat(0xf8f8f8));
    m.rotation.x = Math.PI / 2;
    m.userData = { r: 40 + Math.random() * 120, a: Math.random() * Math.PI * 2, h: 30 + Math.random() * 30, s: 0.2 + Math.random() * 0.3 };
    G.scene.add(m);
    G.birds.push(m);
  }
}

function spawnPets(n) {
  for (let i = 0; i < n; i++) {
    const isCat = i % 2 === 0;
    const g = new THREE.Group();
    const model = cloneStatic(isCat ? 'cat' : 'dog');
    if (model) {
      g.add(model);
    } else {
      const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.25, 0.5, 4, 6), mkMat(isCat ? 0xd9a441 : 0x8a6a4a));
      body.rotation.z = Math.PI / 2; body.position.y = 0.35; body.castShadow = true;
      const head = new THREE.Mesh(new THREE.SphereGeometry(0.25, 10, 8), mkMat(isCat ? 0xd9a441 : 0x8a6a4a));
      head.position.set(0.5, 0.45, 0); g.add(body, head);
    }
    const p = randPos(WORLD.size * 0.9);
    g.position.set(p.x, groundHeight(p.x, p.z), p.z);
    g.userData = { isCat, origin: g.position.clone(), phase: Math.random() * 10 };
    G.scene.add(g);
    G.pets.push(g);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function groundHeight(x, z) {
  const d = Math.hypot(x, z);
  return Math.sin(x * 0.01) * 2 + Math.cos(z * 0.012) * 2 + Math.max(0, (d - 200) * 0.02);
}

// ---------------------------------------------------------------------------
// Input (keyboard for desktop; touch arrives via bridge commands)
// ---------------------------------------------------------------------------
function bindInput() {
  const keys = {};
  window.addEventListener('keydown', (e) => {
    keys[e.code] = true;
    if (e.code === 'KeyE') tryInteract();
    if (e.code === 'Space') { e.preventDefault(); if (G.photoMode) takePhoto(); else G.input.jump = true; }
    if (e.code === 'KeyF') Bridge.emit('requestPanel', { panel: 'missions' });
  });
  window.addEventListener('keyup', (e) => { keys[e.code] = false; });

  G._readKeys = () => {
    let x = 0, y = 0;
    if (keys['KeyW'] || keys['ArrowUp']) y -= 1;
    if (keys['KeyS'] || keys['ArrowDown']) y += 1;
    if (keys['KeyA'] || keys['ArrowLeft']) x -= 1;
    if (keys['KeyD'] || keys['ArrowRight']) x += 1;
    if (x || y) { G.input.x = x; G.input.y = y; }
    else if (!G._touchActive) { G.input.x = 0; G.input.y = 0; }
    G.kbRun = !!keys['ShiftLeft'];
    G.runHeld = G.kbRun || G.touchRun;
  };
}

// ---------------------------------------------------------------------------
// Commands from Flutter
// ---------------------------------------------------------------------------
function bindCommands() {
  Bridge.onCommand(({ name, data }) => {
    Audio.unlock(); // first command from a tap counts as the audio unlock gesture
    switch (name) {
      case 'move': G.input.x = data.x || 0; G.input.y = data.y || 0; G._touchActive = (data.x || data.y) ? true : false; break;
      case 'run': G.touchRun = !!data.on; G.runHeld = G.touchRun || G.kbRun; break;
      case 'jump': G.input.jump = true; break;
      case 'interact': tryInteract(); break;
      case 'photo': if (G.photoMode) takePhoto(); break;
      case 'setWeather': setWeather(data.weather); break;
      case 'setTime': G.time = data.hour ?? G.time; updateSun(); break;
      case 'setTimeScale': G.timeScale = data.scale ?? G.timeScale; break;
      case 'fastTravel': fastTravel(data.id); break;
      case 'setWaypoint': setWaypoint(data.id); break;
      case 'clearWaypoint': G.waypoint = null; G.waypointId = null; G.waypointReachedFired = false; break;
      case 'rahinoSay': rahinoSay(data.text); break;
      case 'rahinoEmote': rahinoEmote(data.emote); break;
      case 'photoMode': setPhotoMode(!!data.on); break;
      case 'pause': G.paused = !!data.on; break;
      case 'setCosmetic': applyCosmetic(data); break;
      case 'spawnPet': spawnFollowPet(data.kind); break;
      case 'density': G.density = data.value ?? 1; break;
      default: break;
    }
  });
}

function setWeather(w) {
  if (!WEATHER.includes(w)) return;
  G.weather = w;
  clearPrecip();
  if (w === 'rain') G.rainSys = makePrecip(0x9fb3c4, 2500, 1.2, true);
  if (w === 'snow') G.snowSys = makePrecip(0xffffff, 1400, 0.35, false);
  Audio.setWeather(w);
  updateSun();
  Bridge.emit('weatherChanged', { weather: w });
}

function clearPrecip() {
  if (G.rainSys) { G.scene.remove(G.rainSys); G.rainSys = null; }
  if (G.snowSys) { G.scene.remove(G.snowSys); G.snowSys = null; }
}

function makePrecip(color, count, size, streak) {
  const geo = new THREE.BufferGeometry();
  const arr = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    arr[i * 3] = (Math.random() - 0.5) * 300;
    arr[i * 3 + 1] = Math.random() * 120;
    arr[i * 3 + 2] = (Math.random() - 0.5) * 300;
  }
  geo.setAttribute('position', new THREE.BufferAttribute(arr, 3));
  const mat = new THREE.PointsMaterial({ color, size, transparent: true, opacity: streak ? 0.5 : 0.85 });
  const pts = new THREE.Points(geo, mat);
  pts.userData = { streak };
  G.scene.add(pts);
  return pts;
}

function animatePrecip(sys, dt) {
  if (!sys) return;
  const pos = sys.geometry.attributes.position;
  const fall = sys.userData.streak ? 60 : 14;
  for (let i = 0; i < pos.count; i++) {
    let y = pos.getY(i) - fall * dt;
    if (y < 0) { y = 120; pos.setX(i, G.player.position.x + (Math.random() - 0.5) * 300); pos.setZ(i, G.player.position.z + (Math.random() - 0.5) * 300); }
    pos.setY(i, y);
  }
  sys.position.set(0, 0, 0);
  pos.needsUpdate = true;
}

function fastTravel(id) {
  const lm = G.landmarks.find((l) => l.def.id === id);
  if (!lm) return;
  const c = lm.center;
  G.player.position.set(c.x + 14, groundHeight(c.x + 14, c.z + 14), c.z + 14);
  G.player.userData.vy = 0;
  rahinoSay(`Fast travelled to ${lm.def.name}!`);
  rahinoEmote('celebrate');
  Bridge.emit('arrived', { id });
}

function setWaypoint(id) {
  const lm = G.landmarks.find((l) => l.def.id === id);
  if (!lm) { G.waypoint = null; G.waypointId = null; return; }
  G.waypoint = lm.center.clone(); G.waypointId = id; G.waypointReachedFired = false;
  rahinoSay(`New destination: ${lm.def.name}. Follow me!`);
  rahinoEmote('point');
}

// ---------------------------------------------------------------------------
// Cosmetics
// ---------------------------------------------------------------------------
function applyCosmetic(data) {
  const parts = G.player.userData.parts;
  if (data.type === 'outfit' && data.color != null) {
    G.player.children.forEach((c) => { if (c.geometry && c.geometry.type === 'CapsuleGeometry') c.material = mkMat(data.color); });
  }
  if (data.type === 'backpack') {
    if (!G.player.userData.pack) {
      const pack = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.8, 0.35), mkMat(data.color || 0x3355cc));
      pack.position.set(0, 1.7, -0.55); pack.castShadow = true; G.player.add(pack); G.player.userData.pack = pack;
    } else G.player.userData.pack.material = mkMat(data.color || 0x3355cc);
  }
  if (data.type === 'rahino' && data.color != null) {
    G.rahino.children.forEach((c) => { if (c.geometry && c.geometry.type === 'CapsuleGeometry') c.material = mkMat(data.color); });
  }
  if (data.type === 'pet') spawnFollowPet(data.kind || 'cat');
}

function spawnFollowPet(kind) {
  if (G.player.userData.followPet) G.scene.remove(G.player.userData.followPet);
  const isCat = kind === 'cat';
  const g = new THREE.Group();
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.22, 0.45, 4, 6), mkMat(isCat ? 0x444 : 0xc99));
  body.rotation.z = Math.PI / 2; body.position.y = 0.3; body.castShadow = true;
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.22, 10, 8), mkMat(isCat ? 0x444 : 0xc99));
  head.position.set(0.45, 0.4, 0); g.add(body, head);
  g.position.copy(G.player.position);
  G.scene.add(g);
  G.player.userData.followPet = g;
}

// ---------------------------------------------------------------------------
// Rahino expressions
// ---------------------------------------------------------------------------
const bubbleEl = document.getElementById('rahino-bubble');
let bubbleTimer = 0;
function rahinoSay(text) {
  bubbleEl.innerHTML = `<span class="name">Rahino</span>${text}`;
  bubbleEl.classList.remove('hidden');
  bubbleTimer = 5.5;
  Bridge.emit('rahinoSpeak', { text });
}
function rahinoEmote(name) {
  G.rahino.userData.emote = name;
  G.rahino.userData.emoteT = name === 'dance' ? 4 : 1.6;
}

// ---------------------------------------------------------------------------
// Interaction
// ---------------------------------------------------------------------------
function tryInteract() {
  if (!G.nearInteract) return;
  const it = G.nearInteract;
  if (it.type === 'chest') {
    if (it.ref.userData.opened) return;
    it.ref.userData.opened = true;
    it.ref.userData.lid.rotation.x = -1.1;
    Audio.chest();
    rahinoEmote('celebrate');
    rahinoSay('A hidden chest! Treasure inside! 🎁');
    Bridge.emit('chestOpened', { });
  } else if (it.type === 'npc') {
    Bridge.emit('npcInteract', { id: it.ref.userData.id, kind: it.ref.userData.kind });
  } else if (it.type === 'landmark') {
    Bridge.emit('landmarkInteract', { id: it.ref.def.id });
  }
}

function setPhotoMode(on) {
  G.photoMode = on;
  document.getElementById('photo-frame').classList.toggle('hidden', !on);
  if (on) rahinoSay('Photo mode on — frame the landmark and snap! 📷');
}

function takePhoto() {
  // find nearest landmark roughly centered in view
  let best = null, bestDot = 0.86;
  const fwd = new THREE.Vector3(); G.camera.getWorldDirection(fwd);
  for (const lm of G.landmarks) {
    TMP.copy(lm.center).sub(G.camera.position).normalize();
    const dot = TMP.dot(fwd);
    const dist = lm.center.distanceTo(G.player.position);
    if (dot > bestDot && dist < 140) { bestDot = dot; best = lm; }
  }
  if (best) {
    Audio.photo();
    rahinoSay(`Great shot of ${best.def.name}! 📸`);
    Bridge.emit('photoTaken', { id: best.def.id });
  } else {
    rahinoSay('Get the landmark inside the frame and try again.');
  }
}

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------
let posEmitTimer = 0;
function loop() {
  const dt = Math.min(G.clock.getDelta(), 0.05);
  if (G.paused) { G.renderer.render(G.scene, G.camera); return; }

  G.time = (G.time + G.timeScale * dt * 60) % 24;
  if (Math.random() < 0.02) updateSun(); // periodic relight

  for (let i = 0; i < G.mixers.length; i++) G.mixers[i].update(dt);

  G._readKeys && G._readKeys();
  updatePlayer(dt);
  updateRahino(dt);
  updateCamera(dt);
  updateEntities(dt);
  updateProximity();
  animateWater(performance.now() / 1000);
  animatePrecip(G.rainSys, dt); animatePrecip(G.snowSys, dt);
  projectLabels();

  // throttled position + clock to Flutter for minimap/compass/HUD
  posEmitTimer += dt;
  if (posEmitTimer > 0.15) {
    posEmitTimer = 0;
    Bridge.emit('position', {
      x: +G.player.position.x.toFixed(1), z: +G.player.position.z.toFixed(1),
      heading: +G.player.rotation.y.toFixed(2),
      hour: +G.time.toFixed(2),
      waypointDist: G.waypoint ? +G.waypoint.distanceTo(G.player.position).toFixed(0) : null,
    });
  }

  if (bubbleTimer > 0) { bubbleTimer -= dt; if (bubbleTimer <= 0) bubbleEl.classList.add('hidden'); }

  G.renderer.render(G.scene, G.camera);
}

function updatePlayer(dt) {
  const p = G.player;
  const ix = G.input.x, iy = G.input.y;
  const mag = Math.hypot(ix, iy);
  const speed = (G.runHeld ? 13 : 7);

  if (mag > 0.08) {
    // input relative to camera yaw
    const ang = Math.atan2(ix, iy); // screen->world
    const worldAng = G.camYaw + ang + Math.PI;
    const dirX = Math.sin(worldAng), dirZ = Math.cos(worldAng);
    p.position.x += dirX * speed * dt;
    p.position.z += dirZ * speed * dt;
    p.rotation.y = worldAng;
    p.userData.speed = speed;
  } else {
    p.userData.speed = 0;
  }

  // jump / gravity
  if (G.input.jump && p.userData.onGround) { p.userData.vy = 9.5; p.userData.onGround = false; }
  G.input.jump = false;
  p.userData.vy -= 26 * dt;
  let groundY = groundHeight(p.position.x, p.position.z);
  p.position.y += p.userData.vy * dt;
  if (p.position.y <= groundY) { p.position.y = groundY; p.userData.vy = 0; p.userData.onGround = true; }

  // clamp to world
  const lim = WORLD.size * 1.4;
  p.position.x = THREE.MathUtils.clamp(p.position.x, -lim, lim);
  p.position.z = THREE.MathUtils.clamp(p.position.z, -lim, lim);

  // limb / clip animation
  animateChar(p, p.userData.speed, dt);

  // follow pet
  if (p.userData.followPet) {
    const pet = p.userData.followPet;
    TMP.copy(p.position).add(new THREE.Vector3(Math.sin(p.rotation.y) * -1.5, 0, Math.cos(p.rotation.y) * -1.5));
    pet.position.lerp(new THREE.Vector3(TMP.x, groundHeight(TMP.x, TMP.z), TMP.z), 0.08);
    pet.lookAt(p.position.x, pet.position.y, p.position.z);
  }
}

function animateLimbs(char, speed, dt) {
  const parts = char.userData.parts; if (!parts) return;
  if (speed > 0.1) {
    char.userData._t = (char.userData._t || 0) + dt * (speed > 9 ? 14 : 9);
    const s = Math.sin(char.userData._t) * (speed > 9 ? 0.9 : 0.6);
    parts.legL.rotation.x = s; parts.legR.rotation.x = -s;
    parts.armL.rotation.x = -s; parts.armR.rotation.x = s;
  } else {
    ['legL', 'legR', 'armL', 'armR'].forEach((k) => { parts[k].rotation.x *= 0.85; });
  }
}

function updateRahino(dt) {
  const r = G.rahino, p = G.player;
  const u = r.userData;
  // follow at side/behind the player
  const off = new THREE.Vector3(Math.sin(p.rotation.y + 0.6) * -2.4, 0, Math.cos(p.rotation.y + 0.6) * -2.4);
  const target = p.position.clone().add(off);
  target.y = groundHeight(target.x, target.z);
  const dist = r.position.distanceTo(target);
  if (dist > 0.4) {
    r.position.lerp(target, Math.min(1, dt * (dist > 8 ? 6 : 3)));
    r.lookAt(p.position.x, r.position.y, p.position.z);
    animateChar(r, dist > 6 ? 12 : 6, dt);
  } else {
    animateChar(r, 0, dt);
  }
  // idle bob
  u.bobT += dt * 3;
  u.parts.head.rotation.z = Math.sin(u.bobT) * 0.05;

  // emotes
  if (u.emoteT > 0) {
    u.emoteT -= dt;
    const k = u.emote;
    if (k === 'wave') u.parts.armR.rotation.z = -1.4 + Math.sin(u.bobT * 6) * 0.4;
    else if (k === 'point') { u.parts.armR.rotation.x = -1.2; }
    else if (k === 'celebrate') { u.parts.armL.rotation.z = 1.4; u.parts.armR.rotation.z = -1.4; r.position.y += Math.abs(Math.sin(u.bobT * 8)) * 0.2; }
    else if (k === 'dance') { r.rotation.y += dt * 4; u.parts.armL.rotation.z = Math.sin(u.bobT * 8); u.parts.armR.rotation.z = -Math.sin(u.bobT * 8); }
    if (u.emoteT <= 0) { u.parts.armR.rotation.set(0, 0, 0); u.parts.armL.rotation.set(0, 0, 0); }
  }
}

function updateCamera(dt) {
  const p = G.player;
  // ease camera yaw toward player's heading when moving
  if (p.userData.speed > 0.1) {
    let target = p.rotation.y;
    let diff = ((target - G.camYaw + Math.PI) % (Math.PI * 2)) - Math.PI;
    G.camYaw += diff * Math.min(1, dt * 1.6);
  }
  const desired = new THREE.Vector3(
    p.position.x - Math.sin(G.camYaw) * G.camDist,
    p.position.y + G.camHeight,
    p.position.z - Math.cos(G.camYaw) * G.camDist
  );
  // keep above ground
  const gy = groundHeight(desired.x, desired.z) + 2.5;
  if (desired.y < gy) desired.y = gy;
  G.camera.position.lerp(desired, Math.min(1, dt * 4));
  G.camera.lookAt(p.position.x, p.position.y + 2, p.position.z);
}

function updateEntities(dt) {
  const t = performance.now() / 1000;
  // NPC wander
  for (const npc of G.npcs) {
    const u = npc.userData;
    u.heading += (Math.random() - 0.5) * dt;
    npc.position.x += Math.sin(u.heading) * u.speed * dt;
    npc.position.z += Math.cos(u.heading) * u.speed * dt;
    if (npc.position.distanceTo(u.origin) > 18) { npc.lookAt(u.origin.x, npc.position.y, u.origin.z); u.heading = Math.atan2(u.origin.x - npc.position.x, u.origin.z - npc.position.z); }
    npc.position.y = groundHeight(npc.position.x, npc.position.z);
    npc.rotation.y = u.heading;
    animateLimbs(npc, u.speed * 8, dt);
  }
  // vehicles along road paths
  for (const v of G.vehicles) {
    const u = v.userData; u.t = (u.t + u.speed * dt) % 1;
    const [a, b] = u.path;
    const x = a[0] + (b[0] - a[0]) * u.t, z = a[1] + (b[1] - a[1]) * u.t;
    v.position.set(x, groundHeight(x, z) + 0.2, z);
    v.rotation.y = Math.atan2(b[0] - a[0], b[1] - a[1]);
  }
  // ferries circle on water
  for (const f of G.ferries) {
    const u = f.userData; u.t = (u.t + u.speed * dt) % 1;
    const ang = u.t * Math.PI * 2;
    f.position.set(60 + Math.cos(ang) * u.radius, 1, Math.sin(ang) * u.radius * 0.5);
    f.rotation.y = -ang;
  }
  // birds
  for (const b of G.birds) {
    const u = b.userData; u.a += u.s * dt;
    b.position.set(Math.cos(u.a) * u.r, u.h + Math.sin(u.a * 3) * 3, Math.sin(u.a) * u.r);
    b.rotation.y = -u.a;
  }
  // pets idle
  for (const pet of G.pets) {
    const u = pet.userData;
    pet.position.x = u.origin.x + Math.sin(t * 0.3 + u.phase) * 3;
    pet.position.z = u.origin.z + Math.cos(t * 0.2 + u.phase) * 3;
    pet.position.y = groundHeight(pet.position.x, pet.position.z);
    pet.rotation.y = t * 0.3 + u.phase;
  }
  // spin coins
  for (const c of G.coins) c.rotation.z += dt * 3;
}

// ---------------------------------------------------------------------------
// Proximity: collect coins, discover landmarks, show interact hints
// ---------------------------------------------------------------------------
const hintEl = document.getElementById('interact-hint');
function updateProximity() {
  const pp = G.player.position;

  // coins
  for (let i = G.coins.length - 1; i >= 0; i--) {
    const c = G.coins[i];
    if (c.position.distanceTo(pp) < 2.2) {
      G.scene.remove(c); G.coins.splice(i, 1);
      Audio.coin();
      Bridge.emit('coinCollected', { remaining: G.coins.length });
    }
  }

  // landmark discovery
  for (const lm of G.landmarks) {
    const d = lm.center.distanceTo(pp);
    if (!lm.discovered && d < 26) {
      lm.discovered = true;
      lm.labelEl.classList.add('discovered');
      Audio.discover();
      Audio.playMusic(lm.def.district); // switch to the district's track/ambience
      rahinoEmote('celebrate');
      rahinoSay(`You discovered ${lm.def.name}! ${lm.def.icon}`);
      Bridge.emit('landmarkDiscovered', { id: lm.def.id, name: lm.def.name });
    }
    if (G.waypointId === lm.def.id && d < 18 && !G.waypointReachedFired) {
      G.waypointReachedFired = true;
      Bridge.emit('waypointReached', { id: lm.def.id });
    }
  }

  // nearest interactable (chest / npc / landmark)
  let near = null, nd = 5.5;
  for (const ch of G.chests) {
    if (ch.userData.opened) continue;
    const d = ch.position.distanceTo(pp);
    if (d < nd) { nd = d; near = { type: 'chest', ref: ch, pos: ch.position, label: 'Open chest' }; }
  }
  for (const npc of G.npcs) {
    const d = npc.position.distanceTo(pp);
    if (d < nd) { nd = d; near = { type: 'npc', ref: npc, pos: npc.position, label: 'Talk to ' + npc.userData.kind }; }
  }
  for (const lm of G.landmarks) {
    const d = lm.center.distanceTo(pp);
    if (d < 12 && d < nd) { nd = d; near = { type: 'landmark', ref: lm, pos: lm.center, label: 'Inspect ' + lm.def.name }; }
  }
  G.nearInteract = near;

  if (near) {
    TMP.copy(near.pos); TMP.y += 3;
    const sp = worldToScreen(TMP);
    if (sp) { hintEl.style.left = sp.x + 'px'; hintEl.style.top = sp.y + 'px'; hintEl.querySelector('span').textContent = near.label; hintEl.classList.remove('hidden'); }
    else hintEl.classList.add('hidden');
    Bridge.emit('interactable', { label: near.label, type: near.type });
  } else {
    hintEl.classList.add('hidden');
    Bridge.emit('interactable', { label: null });
  }
}

// ---------------------------------------------------------------------------
// Screen projection for DOM labels
// ---------------------------------------------------------------------------
function worldToScreen(v) {
  TMP.copy(v).project(G.camera);
  if (TMP.z > 1) return null; // behind camera
  return { x: (TMP.x * 0.5 + 0.5) * window.innerWidth, y: (-TMP.y * 0.5 + 0.5) * window.innerHeight };
}

function projectLabels() {
  for (const lm of G.landmarks) {
    const d = lm.center.distanceTo(G.player.position);
    TMP.copy(lm.center); TMP.y += landmarkLabelHeight(lm.def.type);
    const sp = worldToScreen(TMP);
    if (!sp || d > 320) { lm.labelEl.style.display = 'none'; continue; }
    lm.labelEl.style.display = 'flex';
    lm.labelEl.style.left = sp.x + 'px';
    lm.labelEl.style.top = sp.y + 'px';
    lm.labelEl.classList.toggle('far', d > 160 && !lm.discovered);
  }
  // Rahino bubble follows Rahino head
  if (!bubbleEl.classList.contains('hidden')) {
    TMP.copy(G.rahino.position); TMP.y += 3.4;
    const sp = worldToScreen(TMP);
    if (sp) { bubbleEl.style.left = sp.x + 'px'; bubbleEl.style.top = sp.y + 'px'; }
  }
}

function landmarkLabelHeight(type) {
  switch (type) {
    case 'tower': return 46; case 'monument': return 34; case 'hotel': return 28;
    case 'transport': case 'market': return 16; default: return 10;
  }
}

function onResize() {
  G.camera.aspect = window.innerWidth / window.innerHeight;
  G.camera.updateProjectionMatrix();
  G.renderer.setSize(window.innerWidth, window.innerHeight);
}
