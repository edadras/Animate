/// A famous Istanbul location the player can discover.
class Landmark {
  final String id;
  final String name;
  final String district;
  final String icon;
  final String type;
  final String blurb;
  final String funFact;

  const Landmark({
    required this.id,
    required this.name,
    required this.district,
    required this.icon,
    required this.type,
    required this.blurb,
    required this.funFact,
  });
}
