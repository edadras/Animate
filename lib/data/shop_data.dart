import '../models/shop_item.dart';

/// Reward shop catalogue. `cosmetic` payloads map directly to the 3D engine's
/// applyCosmetic() handler. Colors are plain RGB ints (0xRRGGBB) for three.js.
const List<ShopItem> kShopItems = [
  // ---- Outfits (player) ----
  ShopItem(id: 'outfit_red', name: 'Crimson Explorer', description: 'A bold red travel jacket.', category: ShopCategory.outfit, price: 120, icon: '🧥', cosmetic: {'type': 'outfit', 'color': 0xC0392B}),
  ShopItem(id: 'outfit_blue', name: 'Bosphorus Blue', description: 'Cool blue for breezy days.', category: ShopCategory.outfit, price: 120, icon: '🧥', cosmetic: {'type': 'outfit', 'color': 0x2980B9}),
  ShopItem(id: 'outfit_purple', name: 'Sultan Violet', description: 'Regal purple coat.', category: ShopCategory.outfit, price: 180, icon: '🧥', cosmetic: {'type': 'outfit', 'color': 0x8E44AD}),
  ShopItem(id: 'outfit_gold', name: 'Golden Wanderer', description: 'Shine like the Golden Horn.', category: ShopCategory.outfit, price: 260, icon: '🧥', cosmetic: {'type': 'outfit', 'color': 0xD4AC0D}),

  // ---- Backpacks ----
  ShopItem(id: 'bp_classic', name: 'Classic Daypack', description: 'A reliable traveller\'s backpack.', category: ShopCategory.backpack, price: 90, icon: '🎒', cosmetic: {'type': 'backpack', 'color': 0x2C3E50}),
  ShopItem(id: 'bp_rainbow', name: 'Rahino Rainbow Pack', description: 'Match Rahino\'s iconic colours.', category: ShopCategory.backpack, price: 200, icon: '🎒', cosmetic: {'type': 'backpack', 'color': 0xE74C3C}),
  ShopItem(id: 'bp_explorer', name: 'Expedition Pack', description: 'For the serious adventurer.', category: ShopCategory.backpack, price: 150, icon: '🎒', cosmetic: {'type': 'backpack', 'color': 0x27AE60}),

  // ---- Pets ----
  ShopItem(id: 'pet_cat', name: 'Istanbul Cat', description: 'A loyal street cat companion.', category: ShopCategory.pet, price: 220, icon: '🐱', cosmetic: {'type': 'pet', 'kind': 'cat'}),
  ShopItem(id: 'pet_dog', name: 'Friendly Dog', description: 'A cheerful dog that follows you.', category: ShopCategory.pet, price: 240, icon: '🐶', cosmetic: {'type': 'pet', 'kind': 'dog'}),
  ShopItem(id: 'pet_seagull', name: 'Tame Seagull', description: 'A Bosphorus seagull friend.', category: ShopCategory.pet, price: 300, icon: '🕊️', cosmetic: {'type': 'pet', 'kind': 'cat'}),

  // ---- Skins (player full colour) ----
  ShopItem(id: 'skin_night', name: 'Night Traveller', description: 'A sleek dark traveller look.', category: ShopCategory.skin, price: 180, icon: '🌙', cosmetic: {'type': 'outfit', 'color': 0x2C3E50}),
  ShopItem(id: 'skin_tulip', name: 'Tulip Festival', description: 'Pink like Istanbul\'s spring tulips.', category: ShopCategory.skin, price: 180, icon: '🌷', cosmetic: {'type': 'outfit', 'color': 0xE91E8C}),

  // ---- Rahino costumes ----
  ShopItem(id: 'rahino_gold', name: 'Golden Rahino', description: 'Dress Rahino in shining gold.', category: ShopCategory.rahinoCostume, price: 300, icon: '🦏', cosmetic: {'type': 'rahino', 'color': 0xF1C40F}),
  ShopItem(id: 'rahino_teal', name: 'Teal Rahino', description: 'A fresh teal hoodie for Rahino.', category: ShopCategory.rahinoCostume, price: 220, icon: '🦏', cosmetic: {'type': 'rahino', 'color': 0x1ABC9C}),
  ShopItem(id: 'rahino_night', name: 'Midnight Rahino', description: 'Rahino in deep midnight blue.', category: ShopCategory.rahinoCostume, price: 260, icon: '🦏', cosmetic: {'type': 'rahino', 'color': 0x34495E}),

  // ---- Emotes ----
  ShopItem(id: 'emote_dance', name: 'Rahino Dance', description: 'Make Rahino bust a move!', category: ShopCategory.emote, price: 140, icon: '🕺', cosmetic: {'type': 'emote', 'emote': 'dance'}),
  ShopItem(id: 'emote_celebrate', name: 'Victory Cheer', description: 'A joyful celebration emote.', category: ShopCategory.emote, price: 90, icon: '🎉', cosmetic: {'type': 'emote', 'emote': 'celebrate'}),
  ShopItem(id: 'emote_wave', name: 'Friendly Wave', description: 'Wave hello to NPCs.', category: ShopCategory.emote, price: 60, icon: '👋', cosmetic: {'type': 'emote', 'emote': 'wave'}),

  // ---- Profile frames ----
  ShopItem(id: 'frame_gold', name: 'Golden Frame', description: 'A prestigious gold profile frame.', category: ShopCategory.frame, price: 200, icon: '🖼️'),
  ShopItem(id: 'frame_tulip', name: 'Tulip Frame', description: 'A floral profile frame.', category: ShopCategory.frame, price: 120, icon: '🌸'),
  ShopItem(id: 'frame_wave', name: 'Bosphorus Frame', description: 'A wavy blue profile frame.', category: ShopCategory.frame, price: 120, icon: '🌊'),

  // ---- Special effects ----
  ShopItem(id: 'fx_sparkle', name: 'Sparkle Trail', description: 'Leave a sparkling trail (cosmetic).', category: ShopCategory.effect, price: 160, icon: '✨'),
  ShopItem(id: 'fx_petals', name: 'Petal Burst', description: 'Tulip petals on discovery.', category: ShopCategory.effect, price: 160, icon: '🌸'),

  // ---- Travel gadgets ----
  ShopItem(id: 'gadget_compass', name: 'Golden Compass', description: 'Sharper waypoint guidance.', category: ShopCategory.gadget, price: 180, icon: '🧭'),
  ShopItem(id: 'gadget_camera', name: 'Pro Camera', description: 'Bonus coins on photo missions.', category: ShopCategory.gadget, price: 220, icon: '📸'),
  ShopItem(id: 'gadget_binoculars', name: 'Binoculars', description: 'Spot landmarks from further away.', category: ShopCategory.gadget, price: 160, icon: '🔭'),

  // ---- Rare collectibles ----
  ShopItem(id: 'col_tulip', name: 'Crystal Tulip', description: 'A rare collectible tulip.', category: ShopCategory.collectible, price: 350, icon: '🌷'),
  ShopItem(id: 'col_lamp', name: 'Mosaic Lamp', description: 'A glowing Turkish mosaic lamp.', category: ShopCategory.collectible, price: 400, icon: '🪔'),
  ShopItem(id: 'col_carpet', name: 'Flying Carpet', description: 'A legendary woven carpet.', category: ShopCategory.collectible, price: 500, icon: '🧶'),

  // ---- Premium locations (unlock fast travel targets) ----
  ShopItem(id: 'loc_camlica', name: 'Unlock Çamlıca', description: 'Premium viewpoint on the Asian side.', category: ShopCategory.location, price: 300, icon: '🌆'),
  ShopItem(id: 'loc_pierre', name: 'Unlock Pierre Loti', description: 'Premium hilltop café access.', category: ShopCategory.location, price: 280, icon: '☕'),

  // ---- Travel (consumables) ----
  ShopItem(id: 'fasttravel_pass', name: 'VIP Travel Pass', description: 'Fast travel to ANY landmark, even before you discover it.', category: ShopCategory.travel, price: 280, icon: '⚡'),
  ShopItem(id: 'wheel_ticket', name: 'Lucky Wheel Ticket', description: 'One spin of the Lucky Wheel.', category: ShopCategory.travel, price: 100, icon: '🎡', consumable: true),
  ShopItem(id: 'treasure_map', name: 'Treasure Map', description: 'Reveals a hidden chest location.', category: ShopCategory.travel, price: 120, icon: '🗺️', consumable: true),
];

ShopItem? shopItemById(String id) {
  for (final s in kShopItems) {
    if (s.id == id) return s;
  }
  return null;
}
