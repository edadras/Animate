# 3D models (.glb) drop-in folder

Place glTF-Binary (`.glb`) files here using the **exact filenames** below and the
engine will automatically use them instead of the procedural placeholder meshes.
Anything missing falls back to procedural geometry, so the game always runs.

> The reference art you have (the Rahino mascot sheet) is concept art (PNGs), not
> 3D meshes. To turn it into a model, run it through a 3D pipeline (e.g. a
> modeling tool or an image→3D service) and export a rigged `.glb` named
> `rahino.glb`. The same applies to buildings and props.

## Characters (animated — Idle / Walk / Run clips picked up by name)
| File           | Used for                          |
|----------------|-----------------------------------|
| `rahino.glb`   | Rahino companion mascot           |
| `player.glb`   | The traveler (player character)    |

## Buildings (keyed by landmark `type` in `js/data.js`)
`monument.glb`, `tower.glb`, `market.glb`, `street.glb`, `hotel.glb`,
`transport.glb`, `cafe.glb`, `restaurant.glb`, `bridge.glb`, `park.glb`, `square.glb`

## Props & actors
`tree.glb`, `coin.glb`, `chest.glb`, `npc.glb`, `car.glb`, `bus.glb`,
`ferry.glb`, `cat.glb`, `dog.glb`

## Notes
* Models should be Y-up, in meters, origin at the base/feet. The engine scales
  characters to ~1.0; tune per-model scale in `makeAnimatedChar` / `cloneStatic`
  call sites if needed.
* After adding files, also list them in `pubspec.yaml` under
  `assets/web3d/models/` (the directory is already registered).
* For Draco-compressed models, additionally vendor `DRACOLoader` + the decoder
  and configure it in `js/models.js`.
