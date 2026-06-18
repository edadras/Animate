/// App configuration.
///
/// Set [kCloudBaseUrl] to your backend's base URL to enable cloud saves and the
/// global leaderboard, e.g. 'https://your-api.example.com'. Leave it empty to
/// run fully offline (local save only) — the game works either way.
///
/// The expected REST contract is documented in `server/README.md`, and a tiny
/// reference server lives in `server/index.js`.
const String kCloudBaseUrl = String.fromEnvironment(
  'RAHINO_CLOUD_URL',
  defaultValue: '', // empty = offline-only
);
