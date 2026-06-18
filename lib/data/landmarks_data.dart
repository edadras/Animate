import '../models/landmark.dart';

/// IDs are identical to assets/web3d/js/data.js so the bridge can address the
/// same landmark from Dart or JS.
const List<Landmark> kLandmarks = [
  Landmark(
    id: 'airport', name: 'Istanbul Airport', district: 'Arrival', icon: '✈️', type: 'transport',
    blurb: 'Your journey begins here — one of the world\'s largest airports.',
    funFact: 'IST opened in 2018 and can handle 90 million passengers a year.',
  ),
  Landmark(
    id: 'hagia_sophia', name: 'Hagia Sophia', district: 'Sultanahmet', icon: '🕌', type: 'monument',
    blurb: 'A cathedral, then a mosque, then a museum, now a mosque again.',
    funFact: 'Built in 537 AD, its dome stood as the world\'s largest for ~1000 years.',
  ),
  Landmark(
    id: 'blue_mosque', name: 'Blue Mosque', district: 'Sultanahmet', icon: '🕌', type: 'monument',
    blurb: 'Sultan Ahmed Mosque, famous for its blue İznik tiles and six minarets.',
    funFact: 'It has more than 20,000 handmade ceramic tiles inside.',
  ),
  Landmark(
    id: 'grand_bazaar', name: 'Grand Bazaar', district: 'Sultanahmet', icon: '🛍️', type: 'market',
    blurb: 'One of the oldest and largest covered markets in the world.',
    funFact: 'It has over 4,000 shops along 61 covered streets.',
  ),
  Landmark(
    id: 'egyptian_bazaar', name: 'Egyptian (Spice) Bazaar', district: 'Eminönü', icon: '🌶️', type: 'market',
    blurb: 'A fragrant maze of spices, Turkish delight and dried fruits.',
    funFact: 'Built in 1664, it was funded by taxes on goods from Cairo.',
  ),
  Landmark(
    id: 'galata_bridge', name: 'Galata Bridge', district: 'Eminönü', icon: '🌉', type: 'bridge',
    blurb: 'Anglers line this bridge across the Golden Horn day and night.',
    funFact: 'The lower deck is full of fish restaurants under the roadway.',
  ),
  Landmark(
    id: 'galata_tower', name: 'Galata Tower', district: 'Beyoğlu', icon: '🗼', type: 'tower',
    blurb: 'A medieval stone tower with sweeping views of the old city.',
    funFact: 'Legend says an inventor flew from it with wooden wings in the 1600s.',
  ),
  Landmark(
    id: 'taksim', name: 'Taksim Square', district: 'Beyoğlu', icon: '🟥', type: 'square',
    blurb: 'The bustling heart of modern Istanbul.',
    funFact: 'The Republic Monument here was unveiled in 1928.',
  ),
  Landmark(
    id: 'istiklal', name: 'İstiklal Street', district: 'Beyoğlu', icon: '🚋', type: 'street',
    blurb: 'A lively pedestrian avenue with a famous nostalgic red tram.',
    funFact: 'Nearly 3 million people can walk it on a busy weekend.',
  ),
  Landmark(
    id: 'ortakoy', name: 'Ortaköy', district: 'Beşiktaş', icon: '⛪', type: 'monument',
    blurb: 'A waterfront square beside a baroque mosque under the bridge.',
    funFact: 'Famous for "kumpir" stuffed baked potatoes by the water.',
  ),
  Landmark(
    id: 'maidens_tower', name: "Maiden's Tower", district: 'Bosphorus', icon: '🗼', type: 'tower',
    blurb: 'A tiny tower on its own islet in the Bosphorus.',
    funFact: 'It has served as a lighthouse, quarantine station and customs post.',
  ),
  Landmark(
    id: 'bosphorus', name: 'Bosphorus Waterfront', district: 'Bosphorus', icon: '🌊', type: 'scenic',
    blurb: 'The strait dividing two continents — Europe meets Asia.',
    funFact: 'Ships from the Black Sea to the Mediterranean all pass through here.',
  ),
  Landmark(
    id: 'ferry_eminonu', name: 'Eminönü Ferry Terminal', district: 'Eminönü', icon: '⛴️', type: 'transport',
    blurb: 'Catch a ferry across the water from this busy quay.',
    funFact: 'Commuter ferries have crossed here for over 150 years.',
  ),
  Landmark(
    id: 'ferry_kadikoy', name: 'Kadıköy Ferry Terminal', district: 'Kadıköy', icon: '⛴️', type: 'transport',
    blurb: 'Gateway to the lively Asian-side neighbourhood of Kadıköy.',
    funFact: 'Kadıköy\'s "Moda" coast is a favourite for sunset tea.',
  ),
  Landmark(
    id: 'metro_taksim', name: 'Taksim Metro', district: 'Beyoğlu', icon: '🚇', type: 'transport',
    blurb: 'Hop on the metro to zip across the city.',
    funFact: 'Istanbul\'s first metro line, the Tünel, opened in 1875.',
  ),
  Landmark(
    id: 'gulhane_park', name: 'Gülhane Park', district: 'Sultanahmet', icon: '🌳', type: 'park',
    blurb: 'A historic rose garden beside the Topkapı Palace walls.',
    funFact: 'Once the outer garden of the Ottoman sultans\' palace.',
  ),
  Landmark(
    id: 'pierre_loti', name: 'Pierre Loti Hill', district: 'Eyüp', icon: '☕', type: 'viewpoint',
    blurb: 'A hilltop café with a postcard view of the Golden Horn.',
    funFact: 'Named after a French novelist who loved the view from here.',
  ),
  Landmark(
    id: 'balat', name: 'Balat Alleys', district: 'Fatih', icon: '🏘️', type: 'hidden',
    blurb: 'Rainbow-coloured houses on steep, photogenic lanes.',
    funFact: 'One of Istanbul\'s oldest neighbourhoods, full of antique shops.',
  ),
  Landmark(
    id: 'spice_cafe', name: 'Çorlulu Ali Paşa Café', district: 'Sultanahmet', icon: '☕', type: 'cafe',
    blurb: 'A courtyard café famous for Turkish tea and water pipes.',
    funFact: 'Set inside an 18th-century theological college courtyard.',
  ),
  Landmark(
    id: 'fish_restaurant', name: 'Karaköy Fish House', district: 'Karaköy', icon: '🐟', type: 'restaurant',
    blurb: 'Fresh fish and meze right by the water.',
    funFact: 'The "balık ekmek" fish sandwich is an Istanbul street classic.',
  ),
  Landmark(
    id: 'grand_hotel', name: 'Pera Grand Hotel', district: 'Beyoğlu', icon: '🏨', type: 'hotel',
    blurb: 'A grand old hotel that hosted writers and spies.',
    funFact: 'Agatha Christie reputedly wrote part of a novel in old Pera.',
  ),
  Landmark(
    id: 'camlica_view', name: 'Çamlıca Viewpoint', district: 'Üsküdar', icon: '🌆', type: 'viewpoint',
    blurb: 'The highest hill on the Asian side, with a 360° city panorama.',
    funFact: 'Çamlıca Mosque here is the largest mosque in modern Turkey.',
  ),
];

Landmark? landmarkById(String id) {
  for (final l in kLandmarks) {
    if (l.id == id) return l;
  }
  return null;
}
