import 'farm_catalog.dart';
import 'farm_mood.dart';

class FarmState {
  const FarmState({
    required this.healthStartedAt,
    required this.healthFullUntil,
    required this.healthDuration,
    required this.pendingCoins,
    required this.coins,
    required this.foodInventory,
    required this.ownedPetIds,
    required this.selectedPetId,
    required this.selectedFoodId,
    required this.adGrantsLeft,
  });

  final DateTime healthStartedAt;
  final DateTime healthFullUntil;
  final Duration healthDuration;
  final int pendingCoins;
  final int coins;
  final Map<String, int> foodInventory;
  final Set<String> ownedPetIds;
  final String selectedPetId;
  final String selectedFoodId;
  final int adGrantsLeft;

  Duration remainingAt(DateTime now) {
    final value = healthFullUntil.difference(now);
    return value.isNegative ? Duration.zero : value;
  }

  double healthAt(DateTime now) {
    if (healthDuration.inMilliseconds <= 0) return 0;
    return (remainingAt(now).inMilliseconds / healthDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  FarmMood moodAt(DateTime now) {
    final health = healthAt(now);
    if (health >= .71) return FarmMood.happy;
    if (health >= .40) return FarmMood.normal;
    return FarmMood.hungry;
  }

  bool shouldConfirmFeed(DateTime now) =>
      healthAt(now) > FarmCatalog.overwriteRatio &&
      remainingAt(now) > FarmCatalog.overwriteMinimum;
}
