// Minimal reference backend for Rahino cloud saves + global leaderboard.
// In-memory store (swap for a real DB in production). Deploy anywhere Node runs,
// then set RAHINO_CLOUD_URL when building the app:
//   flutter run --dart-define=RAHINO_CLOUD_URL=https://your-host
//
//   npm install && npm start   (listens on $PORT or 8090)

const express = require('express');
const app = express();
app.use(express.json({ limit: '1mb' }));

const saves = new Map();   // playerId -> profile
const scores = new Map();  // playerId -> { name, score, level, updated }

// --- Cloud save ---
app.post('/save', (req, res) => {
  const { playerId, profile } = req.body || {};
  if (!playerId || !profile) return res.status(400).json({ error: 'playerId and profile required' });
  saves.set(playerId, profile);
  res.json({ ok: true });
});

app.get('/save', (req, res) => {
  const { playerId } = req.query;
  const profile = saves.get(playerId);
  if (!profile) return res.status(404).json({ error: 'not found' });
  res.json({ profile });
});

// --- Leaderboard ---
app.post('/score', (req, res) => {
  const { playerId, name, score, level } = req.body || {};
  if (!playerId) return res.status(400).json({ error: 'playerId required' });
  const prev = scores.get(playerId);
  // keep the best score per player
  if (!prev || (score || 0) > prev.score) {
    scores.set(playerId, { playerId, name: name || 'Player', score: score || 0, level: level || 1, updated: Date.now() });
  }
  res.json({ ok: true });
});

app.get('/leaderboard', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit || '20', 10), 100);
  const list = [...scores.values()].sort((a, b) => b.score - a.score).slice(0, limit);
  res.json(list);
});

app.get('/', (_req, res) => res.json({ service: 'rahino-cloud', ok: true }));

const PORT = process.env.PORT || 8090;
app.listen(PORT, () => console.log(`Rahino cloud backend listening on :${PORT}`));
