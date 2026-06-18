enum ShopCategory {
  outfit,
  backpack,
  pet,
  skin,
  rahinoCostume,
  emote,
  frame,
  effect,
  gadget,
  collectible,
  location,
  travel, // fast travel, lucky wheel tickets, treasure maps
}

extension ShopCategoryX on ShopCategory {
  String get label {
    switch (this) {
      case ShopCategory.outfit: return 'Outfits';
      case ShopCategory.backpack: return 'Backpacks';
      case ShopCategory.pet: return 'Pets';
      case ShopCategory.skin: return 'Skins';
      case ShopCategory.rahinoCostume: return 'Rahino';
      case ShopCategory.emote: return 'Emotes';
      case ShopCategory.frame: return 'Frames';
      case ShopCategory.effect: return 'Effects';
      case ShopCategory.gadget: return 'Gadgets';
      case ShopCategory.collectible: return 'Collectibles';
      case ShopCategory.location: return 'Locations';
      case ShopCategory.travel: return 'Travel';
    }
  }

  String get icon {
    switch (this) {
      case ShopCategory.outfit: return '👕';
      case ShopCategory.backpack: return '🎒';
      case ShopCategory.pet: return '🐾';
      case ShopCategory.skin: return '🎨';
      case ShopCategory.rahinoCostume: return '🦏';
      case ShopCategory.emote: return '🕺';
      case ShopCategory.frame: return '🖼️';
      case ShopCategory.effect: return '✨';
      case ShopCategory.gadget: return '🧭';
      case ShopCategory.collectible: return '💎';
      case ShopCategory.location: return '🗺️';
      case ShopCategory.travel: return '⚡';
    }
  }
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final ShopCategory category;
  final int price;
  final String icon;

  /// Payload forwarded to the 3D engine when equipped, e.g.
  /// { "type": "outfit", "color": 0xFF2E8B57 } or { "type": "pet", "kind": "cat" }.
  final Map<String, dynamic>? cosmetic;

  /// Consumable items (lucky wheel tickets, treasure maps, fast travel passes)
  /// are not "equipped" but spent.
  final bool consumable;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.icon,
    this.cosmetic,
    this.consumable = false,
  });
}
