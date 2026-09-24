import 'package:flutter/material.dart';

import '../../domain/store_category.dart';
import 'store_assets.dart';

class StoreTabs extends StatelessWidget {
  const StoreTabs({
    super.key,
    required this.panelWidth,
    required this.selected,
    required this.onSelected,
  });

  final double panelWidth;
  final StoreCategory selected;
  final ValueChanged<StoreCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = StoreCategory.values;
    final factor = ((.86 / categories.length - .004) / .83).clamp(0.0, .2425);
    final tabWidth = panelWidth * factor;
    final tabHeight = panelWidth * .2425;
    final overlap = panelWidth * (factor * .085 - .002);

    return Positioned(
      left: panelWidth * .0715,
      top: panelWidth * .3151,
      width: panelWidth * .86,
      height: tabHeight,
      child: Stack(
        children: [
          for (var i = 0; i < categories.length; i++)
            Positioned(
              left: i * (tabWidth - overlap * 2),
              width: tabWidth,
              height: tabHeight,
              child: _StoreTab(
                category: categories[i],
                selected: categories[i] == selected,
                panelWidth: panelWidth,
                onTap: () => onSelected(categories[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreTab extends StatelessWidget {
  const _StoreTab({
    required this.category,
    required this.selected,
    required this.panelWidth,
    required this.onTap,
  });

  final StoreCategory category;
  final bool selected;
  final double panelWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            selected ? StoreAssets.tabSelected : StoreAssets.tabNormal,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: panelWidth * .015,
          right: panelWidth * .015,
          // top: panelWidth * .01,
          bottom: panelWidth * .095,
          height: panelWidth * .095,
          child: Image.asset(_iconFor(category), fit: BoxFit.contain),
        ),
        Positioned(
          left: panelWidth * .010,
          right: panelWidth * .010,
          top: selected ? panelWidth * .145 : panelWidth * .155,
          height: panelWidth * .042,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              category.label,
              maxLines: 1,
              style: TextStyle(
                color: const Color(0xFF5A3413),
                fontSize: panelWidth * .025,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  String _iconFor(StoreCategory category) => switch (category) {
    StoreCategory.boosters => 'assets/store/boosters/icon-booster-hammer.webp',
    StoreCategory.chests => 'assets/store/chests/icon-chest.webp',
    StoreCategory.coins => 'assets/store/coins/icon-coin.webp',
    StoreCategory.dino => 'assets/store/icon-dino.webp',
    StoreCategory.pet => 'assets/store/pets/pet-icon.webp',
  };
}
