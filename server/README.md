# Rahino Cloud Backend (reference)

A tiny REST backend the Flutter client (`lib/services/cloud_service.dart`) talks
to for **cloud saves** and the **global leaderboard**. It uses an in-memory store
for clarity — replace with Postgres/Redis/Firebase/Supabase for production.

## Run
```bash
cd server
npm install
npm start          # http://localhost:8090
```

## Point the app at it
```bash
flutter run --dart-define=RAHINO_CLOUD_URL=http://10.0.2.2:8090   # Android emulator
# or set kCloudBaseUrl in lib/config.dart
```
Leave the URL empty to run fully offline (local save only).

## REST contract
| Method | Path           | Body / Query                                   | Returns                            |
|--------|----------------|------------------------------------------------|------------------------------------|
| POST   | `/save`        | `{ playerId, profile }`                         | `{ ok: true }`                     |
| GET    | `/save`        | `?playerId=...`                                | `{ profile }` or `404`             |
| POST   | `/score`       | `{ playerId, name, score, level }`             | `{ ok: true }` (keeps best score)  |
| GET    | `/leaderboard` | `?limit=20`                                    | `[ { playerId, name, score, level } ]` |

`profile` is exactly the JSON produced by `PlayerProfile.toJson()`, so saves are
forward-compatible with the client model. The client never blocks on the network:
every call is best-effort and falls back to local data when offline.
