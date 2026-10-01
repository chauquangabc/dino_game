enum FarmFoodAcquisition { coins, store, rewardedAd }

class FarmFood {
  const FarmFood({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.duration,
    required this.startingCount,
    required this.acquisition,
    this.price = 0,
  });

  final String id;
  final String name;
  final String assetPath;
  final Duration duration;
  final int startingCount;
  final FarmFoodAcquisition acquisition;
  final int price;
}
