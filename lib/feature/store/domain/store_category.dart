enum StoreCategory {
  boosters('BOOSTERS'),
  chests('CHESTS'),
  coins('COINS'),
  dino('DINO'),
  pet('PET');

  const StoreCategory(this.label);

  final String label;
}
