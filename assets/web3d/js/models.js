// ============================================================================
// GLB model pipeline.
//
// Drop real glTF/GLB files into assets/web3d/models/ using the names in
// MODEL_MANIFEST and they automatically replace the procedural meshes — Rahino,
// the player, buildings, vehicles, props, animals. Anything missing simply
// falls back to the built-in procedural geometry, so the game always runs.
//
// Animated characters (player, rahino) support Idle/Walk/Run clips by name and
// are crossfaded by movement speed.
// ============================================================================
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { clone as skeletonClone } from 'three/addons/utils/SkeletonUtils.js';
import { Bridge } from './bridge.js';

export const MODEL_MANIFEST = {
  // characters (animated)
  rahino: './models/rahino.glb',
  player: './models/player.glb',
  // buildings — keyed by landmark "type" (see data.js)
  building_monument: './models/monument.glb',
  building_tower: './models/tower.glb',
  building_market: './models/market.glb',
  building_street: './models/street.glb',
  building_hotel: './models/hotel.glb',
  building_transport: './models/transport.glb',
  building_cafe: './models/cafe.glb',
  building_restaurant: './models/restaurant.glb',
  building_bridge: './models/bridge.glb',
  building_park: './models/park.glb',
  building_square: './models/square.glb',
  // props / actors
  tree: './models/tree.glb',
  coin: './models/coin.glb',
  chest: './models/chest.glb',
  npc: './models/npc.glb',
  car: './models/car.glb',
  bus: './models/bus.glb',
  ferry: './models/ferry.glb',
  cat: './models/cat.glb',
  dog: './models/dog.glb',
};

const registry = {}; // id -> { scene, animations }

export async function preloadModels() {
  const loader = new GLTFLoader();
  const ids = Object.keys(MODEL_MANIFEST);
  let loaded = 0;
  await Promise.all(ids.map((id) => new Promise((resolve) => {
    loader.load(
      MODEL_MANIFEST[id],
      (gltf) => {
        gltf.scene.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
        registry[id] = { scene: gltf.scene, animations: gltf.animations || [] };
        loaded++;
        resolve();
      },
      undefined,
      () => resolve(), // missing/failed -> procedural fallback
    );
  })));
  Bridge.emit('modelsLoaded', { loaded, total: ids.length });
  return loaded;
}

export function hasModel(id) { return !!registry[id]; }

// A fresh, skeleton-aware instance plus a mixer if the model is animated.
export function instantiate(id) {
  const entry = registry[id];
  if (!entry) return null;
  const root = skeletonClone(entry.scene);
  const mixer = (entry.animations && entry.animations.length) ? new THREE.AnimationMixer(root) : null;
  return { root, mixer, animations: entry.animations };
}

// Static clone for props/buildings (no animation needed). Returns Object3D|null.
export function cloneStatic(id) {
  const inst = instantiate(id);
  return inst ? inst.root : null;
}

// Create (and start, at weight 0) an action matching one of `names`.
export function getAction(inst, names) {
  if (!inst || !inst.mixer) return null;
  let clip = null;
  for (const n of names) {
    const c = THREE.AnimationClip.findByName(inst.animations, n);
    if (c) { clip = c; break; }
  }
  if (!clip) return null;
  const action = inst.mixer.clipAction(clip);
  action.enabled = true;
  action.setEffectiveWeight(0);
  action.play();
  return action;
}

export function getActionByIndex(inst, i) {
  if (!inst || !inst.mixer || !inst.animations[i]) return null;
  const action = inst.mixer.clipAction(inst.animations[i]);
  action.enabled = true;
  action.setEffectiveWeight(0);
  action.play();
  return action;
}
