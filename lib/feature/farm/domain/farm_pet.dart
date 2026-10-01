import 'farm_mood.dart';

class FarmPetPlacement {
  const FarmPetPlacement({
    required this.x,
    required this.feetY,
    required this.height,
  });

  final double x;
  final double feetY;
  final double height;
}

class FarmPet {
  const FarmPet({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.moodAssets,
  });

  final String id;
  final String name;
  final String thumbnail;
  final Map<FarmMood, String> moodAssets;

  String assetFor(FarmMood mood) => moodAssets[mood] ?? thumbnail;
}
