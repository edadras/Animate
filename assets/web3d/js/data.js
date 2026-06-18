// ============================================================================
// World data for the 3D engine. Coordinates are laid out so the historic
// peninsula sits south of the Golden Horn, Beyoğlu/Galata north of it, and the
// Asian side (Kadıköy/Üsküdar) across the Bosphorus to the east.
// IDs are kept identical to the Dart `landmarks_data.dart` so the bridge can
// reference landmarks by id from either side.
// ============================================================================

export const WORLD = {
  size: 600,          // half-extent of the playable ground plane
  waterLevel: 0.0,
};

// [x, z] in world units. y is ground.
export const LANDMARKS = [
  { id: 'airport',       name: 'Istanbul Airport',  icon: '✈️', pos: [-260, -210], district: 'Arrival',    type: 'transport' },
  { id: 'hagia_sophia',  name: 'Hagia Sophia',      icon: '🕌', pos: [40, 150],    district: 'Sultanahmet', type: 'monument' },
  { id: 'blue_mosque',   name: 'Blue Mosque',       icon: '🕌', pos: [90, 175],    district: 'Sultanahmet', type: 'monument' },
  { id: 'grand_bazaar',  name: 'Grand Bazaar',      icon: '🛍️', pos: [-30, 120],   district: 'Sultanahmet', type: 'market' },
  { id: 'egyptian_bazaar',name:'Egyptian Bazaar',   icon: '🌶️', pos: [-10, 60],    district: 'Eminönü',    type: 'market' },
  { id: 'galata_bridge', name: 'Galata Bridge',     icon: '🌉', pos: [-5, 10],     district: 'Eminönü',    type: 'bridge' },
  { id: 'galata_tower',  name: 'Galata Tower',      icon: '🗼', pos: [-15, -55],   district: 'Beyoğlu',    type: 'tower' },
  { id: 'taksim',        name: 'Taksim Square',     icon: '🟥', pos: [-40, -150],  district: 'Beyoğlu',    type: 'square' },
  { id: 'istiklal',      name: 'İstiklal Street',   icon: '🚋', pos: [-28, -105],  district: 'Beyoğlu',    type: 'street' },
  { id: 'ortakoy',       name: 'Ortaköy',           icon: '⛪', pos: [120, -140],  district: 'Beşiktaş',   type: 'monument' },
  { id: 'maidens_tower', name: "Maiden's Tower",    icon: '🗼', pos: [200, 90],    district: 'Bosphorus',  type: 'tower' },
  { id: 'bosphorus',     name: 'Bosphorus Waterfront', icon: '🌊', pos: [150, -20], district: 'Bosphorus', type: 'scenic' },
  { id: 'ferry_eminonu', name: 'Eminönü Ferry Terminal', icon: '⛴️', pos: [25, 25], district: 'Eminönü',  type: 'transport' },
  { id: 'ferry_kadikoy', name: 'Kadıköy Ferry Terminal', icon: '⛴️', pos: [240, 30], district: 'Kadıköy',  type: 'transport' },
  { id: 'metro_taksim',  name: 'Taksim Metro',      icon: '🚇', pos: [-55, -160],  district: 'Beyoğlu',    type: 'transport' },
  { id: 'gulhane_park',  name: 'Gülhane Park',      icon: '🌳', pos: [70, 110],    district: 'Sultanahmet', type: 'park' },
  { id: 'pierre_loti',   name: 'Pierre Loti Hill',  icon: '☕', pos: [-150, 80],   district: 'Eyüp',       type: 'viewpoint' },
  { id: 'balat',         name: 'Balat Alleys',      icon: '🏘️', pos: [-90, 70],    district: 'Fatih',      type: 'hidden' },
  { id: 'spice_cafe',    name: 'Çorlulu Ali Paşa Café', icon: '☕', pos: [5, 100], district: 'Sultanahmet', type: 'cafe' },
  { id: 'fish_restaurant',name:'Karaköy Fish House', icon: '🐟', pos: [-12, -25],  district: 'Karaköy',    type: 'restaurant' },
  { id: 'grand_hotel',   name: 'Pera Grand Hotel',  icon: '🏨', pos: [-45, -80],   district: 'Beyoğlu',    type: 'hotel' },
  { id: 'camlica_view',  name: 'Çamlıca Viewpoint', icon: '🌆', pos: [300, -60],   district: 'Üsküdar',    type: 'viewpoint' },
];

// District ambient palettes: sky tint + ground/building accent + music cue id.
export const DISTRICTS = {
  Sultanahmet: { accent: 0xd9a441, music: 'ottoman' },
  'Eminönü':   { accent: 0xc98b3a, music: 'bazaar' },
  'Beyoğlu':   { accent: 0xb24a52, music: 'pera' },
  'Beşiktaş':  { accent: 0x4a82b2, music: 'bosphorus' },
  Bosphorus:   { accent: 0x2f6e9e, music: 'bosphorus' },
  'Kadıköy':   { accent: 0x6a9a6a, music: 'ferry' },
  Fatih:       { accent: 0xc06a4a, music: 'balat' },
  'Eyüp':      { accent: 0x7a9a5a, music: 'serene' },
  'Karaköy':   { accent: 0x9a6a4a, music: 'pera' },
  'Üsküdar':   { accent: 0x5a7a9a, music: 'serene' },
  Arrival:     { accent: 0x8a8a9a, music: 'arrival' },
};

// Weather presets the bridge can switch to.
export const WEATHER = ['sunny', 'sunset', 'rain', 'fog', 'snow'];
