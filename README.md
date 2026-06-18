# 🧭 Rahino: Istanbul Treasure Hunt

A **3D travel-adventure game** built with **Flutter** (mobile, iOS & Android) wrapping a
**real WebGL / Three.js 3D world**. You arrive in Istanbul as a traveler, guided by
**Rahino** — a friendly rhino companion — and explore a stylized 3D recreation of the
city: discover landmarks, complete missions, collect coins & chests, level up, and spend
your rewards in the shop. No combat — only **adventure, discovery, exploration and travel**.

> ### Honest scope note (please read)
> This is a **complete, playable foundation**, not a shipped AAA title.
> * **"Higgsfield MCP" is not used.** It was not available as a tool in the build
>   environment, and the Rahino reference art you provided is concept art (PNGs), not
>   rigged 3D models. The in-game Rahino and city are therefore built from **procedural
>   stylized 3D geometry** in Three.js. When you have real `.glb`/`.png` assets, they can
>   be dropped into the engine to replace the primitives.
> * The world is **stylized low-poly 3D** with day/night, weather, soft shadows, animated
>   water and a realistic sky — genuinely 3D, but not photoreal.
> * All the **game systems are fully implemented** (see below). Missions are generated in
>   the hundreds from templates × landmarks.

---

## 🏗️ Architecture — Hybrid Flutter + WebGL

```
┌──────────────────────────── Flutter (Dart) ────────────────────────────┐
│  Premium native UI · save system · economy · missions · achievements   │
│  · daily/weekly live-ops · shop · profile · map · HUD · touch controls  │
│                                                                         │
│        GameState (ChangeNotifier)  ⇄  GameBridge  ⇄  evaluateJavascript │
└───────────────────────────────────┬─────────────────────────────────────┘
                                     │  JS message bridge
┌────────────────────────────────────▼────────────────────────────────────┐
│  assets/web3d/  —  Three.js / WebGL 3D engine (embedded InAppWebView)     │
│  3D Istanbul · player + Rahino · NPCs · vehicles · ferries · birds/pets   │
│  · coins/chests · day-night · weather · camera · procedural audio         │
└──────────────────────────────────────────────────────────────────────────┘
```

* **Events out** (engine → Flutter): `coinCollected`, `chestOpened`,
  `landmarkDiscovered`, `waypointReached`, `photoTaken`, `npcInteract`, `position`, …
* **Commands in** (Flutter → engine): `move`, `run`, `jump`, `interact`, `setWeather`,
  `setTime`, `setWaypoint`, `fastTravel`, `setCosmetic`, `rahinoSay`, `rahinoEmote`, …

### Project layout
```
lib/
  main.dart                  app entry + provider
  models/                    PlayerProfile, Mission, ShopItem, Achievement, Landmark
  data/                      landmarks, mission generator, shop, achievements, world coords
  services/
    save_service.dart        offline-first JSON save (shared_preferences)
    game_state.dart          the game brain (economy, XP/levels, missions, live-ops)
  bridge/game_bridge.dart    Flutter ⇄ 3D engine bridge
  ui/                        screens, panels (missions/shop/profile/map/live), widgets
assets/web3d/                the 3D engine (index.html, styles.css, js/*)
```

---

## ▶️ Running it

This repo contains the **Dart sources + 3D engine**. Generate the platform runners once:

```bash
flutter create . --platforms=android,ios,web   # adds android/ ios/ web/ runners
flutter pub get
flutter run                                     # on a device/emulator
```

**Notes**
* Three.js loads from a CDN on first run, so the **first launch needs network**. To ship
  fully offline, download `three.module.js` + the `examples/jsm` addons into
  `assets/web3d/js/vendor/` and point the import map in `index.html` at them.
* `flutter_inappwebview` requires Android `minSdkVersion 19+` and iOS `12+`.

### Want to see the 3D world without Flutter?
The engine is a self-contained web app — serve it and open in a browser:
```bash
cd assets/web3d && python3 -m http.server 8080   # then open http://localhost:8080
```
Desktop controls: **WASD** move · **Shift** run · **Space** jump · **E** interact · **F** missions.

---

## 🎮 Features implemented

**World** — 22 Istanbul landmarks (Hagia Sophia, Blue Mosque, Galata Tower & Bridge,
Grand & Egyptian Bazaars, Bosphorus, Ortaköy, Taksim, İstiklal, Maiden's Tower, ferry
terminals, metro, parks, cafés, restaurants, hotels, viewpoints, hidden alleys),
day/night cycle, 5 weather states (sunny/sunset/rain/fog/snow), animated water,
realistic sky, moving cars & buses, ferries, seagulls, street cats & dogs, wandering NPCs.

**Characters** — third-person traveler + **Rahino** companion who follows you, waves,
points, celebrates, dances, and talks via speech bubbles. Smooth movement, running,
jumping, follow-camera.

**Missions** — hundreds generated across types: visit, photo, collect coins, open chests,
talk to NPCs, deliver luggage, escort tourists, public-transport, find local food, visit
museums, souvenir hunts, hidden artifacts, secret spots, walking challenges, travel
quizzes — plus **daily challenges** and a **weekly quest**. Rewards: coins, XP,
collectibles, mystery boxes.

**Progression** — XP & levels, 25 achievements with unlockable **titles**, daily login
streak rewards, weekly objective, seasonal event banner, local leaderboard, full profile.

**Economy & shop** — outfits, backpacks, pets, skins, Rahino costumes, emotes, profile
frames, effects, gadgets, rare collectibles, premium location unlocks, VIP fast-travel,
Lucky Wheel tickets, treasure maps. Cosmetics apply live to the 3D characters.

**Other** — fast travel, waypoints + compass distance, minimap, interaction prompts,
procedural ambient audio + SFX, offline-first save, immersive landscape touch UI.

---

## 🔌 Extending toward the full vision
* Replace procedural meshes with real `.glb` models (Rahino, buildings, props).
* Bundle Three.js locally for offline play.
* Wire `SaveService` to a backend for **cloud saves & global leaderboards**.
* Add real Turkish music / ambience tracks (hook points are in `assets/web3d/js/audio.js`).
