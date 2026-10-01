import 'farm_food.dart';
import 'farm_mood.dart';
import 'farm_pet.dart';

abstract final class FarmCatalog {
  static const coinsPerHour = 20;
  static const pendingCoinsCap = 2000;
  static const maxOffline = Duration(hours: 24);
  static const rewardedAdDailyCap = 5;
  static const overwriteRatio = .30;
  static const overwriteMinimum = Duration(minutes: 10);
  static const defaultPetId = 'triceratops';

  static const portraitPlacement = FarmPetPlacement(
    x: .5,
    feetY: .515,
    height: .1225,
  );
  static const landscapePlacement = FarmPetPlacement(
    x: .5,
    feetY: .610,
    height: .238,
  );

  static const foods = <FarmFood>[
    FarmFood(
      id: 'food_1',
      name: 'BERRY SNACK',
      assetPath: 'assets/store/pets/fruit.webp',
      duration: Duration(hours: 1),
      startingCount: 5,
      acquisition: FarmFoodAcquisition.coins,
      price: 5,
    ),
    FarmFood(
      id: 'food_2',
      name: 'MEAT BOWL',
      assetPath: 'assets/store/pets/hamburger.webp',
      duration: Duration(hours: 6),
      startingCount: 3,
      acquisition: FarmFoodAcquisition.coins,
      price: 25,
    ),
    FarmFood(
      id: 'food_3',
      name: 'GIANT STEAK',
      assetPath: 'assets/store/pets/pork-chop.webp',
      duration: Duration(hours: 12),
      startingCount: 1,
      acquisition: FarmFoodAcquisition.store,
      price: 45,
    ),
    FarmFood(
      id: 'food_4',
      name: 'DINO FEAST',
      assetPath: 'assets/store/pets/chicken-drumstick.webp',
      duration: Duration(hours: 24),
      startingCount: 0,
      acquisition: FarmFoodAcquisition.rewardedAd,
      price: 0,
    ),
  ];

  static const pets = <FarmPet>[
    FarmPet(
      id: 'triceratops',
      name: 'TRICERATOPS',
      thumbnail: 'assets/store/pets/green-triceratops.webp',
      moodAssets: {
        FarmMood.happy:
            'assets/farm/triceratops/character_walking_transparent.webp',
        FarmMood.normal: 'assets/farm/triceratops/idle_transparent.webp',
        FarmMood.hungry: 'assets/farm/triceratops/sad_transparent.webp',
      },
    ),
    FarmPet(
      id: 'trex',
      name: 'T-REX',
      thumbnail: 'assets/store/pets/t-rex.webp',
      moodAssets: {
        FarmMood.happy: 'assets/farm/t-rex/happy_transparent.webp',
        FarmMood.normal: 'assets/farm/t-rex/normal_transparent.webp',
        FarmMood.hungry: 'assets/farm/t-rex/sad_transparent.webp',
      },
    ),
    FarmPet(
      id: 'pteranodon',
      name: 'PTERANODON',
      thumbnail: 'assets/store/pets/pteranodon.webp',
      moodAssets: {
        FarmMood.happy: 'assets/farm/pteranodon/happy_transparent.webp',
        FarmMood.normal: 'assets/farm/pteranodon/normal_transparent.webp',
        FarmMood.hungry: 'assets/farm/pteranodon/sad_transparent.webp',
      },
    ),
  ];

  static FarmFood? food(String id) {
    for (final item in foods) {
      if (item.id == id) return item;
    }
    return null;
  }

  static FarmPet pet(String id) =>
      pets.firstWhere((item) => item.id == id, orElse: () => pets.first);
}
