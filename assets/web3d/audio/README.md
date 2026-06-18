# Music & ambience drop-in folder

Drop looping music tracks here and they replace the procedural soundtrack.
Filenames are matched in `TRACK_MANIFEST` (see `js/audio.js`):

| File                  | Plays in district        |
|-----------------------|--------------------------|
| `istanbul_theme.mp3`  | default / menu fallback  |
| `ottoman.mp3`         | Sultanahmet              |
| `bazaar.mp3`          | Eminönü                  |
| `pera.mp3`            | Beyoğlu                  |
| `bosphorus.mp3`       | Bosphorus / Beşiktaş     |

If a file is absent, a **Turkish-makam procedural soundtrack** (drone + ney-like
lead + oud-like plucks over a Hijaz-ish scale) is synthesised live instead, and a
procedural rain bed fades in during rainy weather.

**Licensing:** ship only music you have the rights to. Royalty-free Turkish /
Ottoman-style tracks (or your own compositions) work well here. Keep files small
(mono, ~96–128 kbps) so they bundle into the app cleanly.
