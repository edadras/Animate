import 'package:flutter/painting.dart';

/// World [x, z] positions mirroring assets/web3d/js/data.js. Used by the
/// minimap and the full map panel so the Dart UI matches the 3D world.
const Map<String, Offset> kWorldCoords = {
  'airport': Offset(-260, -210),
  'hagia_sophia': Offset(40, 150),
  'blue_mosque': Offset(90, 175),
  'grand_bazaar': Offset(-30, 120),
  'egyptian_bazaar': Offset(-10, 60),
  'galata_bridge': Offset(-5, 10),
  'galata_tower': Offset(-15, -55),
  'taksim': Offset(-40, -150),
  'istiklal': Offset(-28, -105),
  'ortakoy': Offset(120, -140),
  'maidens_tower': Offset(200, 90),
  'bosphorus': Offset(150, -20),
  'ferry_eminonu': Offset(25, 25),
  'ferry_kadikoy': Offset(240, 30),
  'metro_taksim': Offset(-55, -160),
  'gulhane_park': Offset(70, 110),
  'pierre_loti': Offset(-150, 80),
  'balat': Offset(-90, 70),
  'spice_cafe': Offset(5, 100),
  'fish_restaurant': Offset(-12, -25),
  'grand_hotel': Offset(-45, -80),
  'camlica_view': Offset(300, -60),
};

/// Half-extent of the world used to normalise coordinates onto the minimap.
const double kWorldHalf = 360.0;
