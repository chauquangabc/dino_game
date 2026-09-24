import 'store_category.dart';

enum StoreGrantType { tool, chest, coins, dino, pet, food }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.category,
    required this.name,
    required this.quantity,
    required this.price,
    required this.assetPath,
    required this.sortOrder,
    required this.grantType,
    required this.grantId,
    this.currency = 'COIN',
    this.isUnique = false,
  });

  final String id;
  final StoreCategory category;
  final String name;
  final int quantity;
  final num price;
  final String currency;
  final String assetPath;
  final int sortOrder;
  final StoreGrantType grantType;
  final String grantId;
  final bool isUnique;

  bool get isIap => currency == 'USD';
}
