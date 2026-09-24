import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/store_catalog.dart';
import '../../domain/store_category.dart';
import '../../domain/store_product.dart';
import '../../domain/store_state.dart';
import 'store_assets.dart';
import 'store_product_list.dart';
import 'store_tabs.dart';
import 'store_wallet.dart';

class StorePopup extends StatelessWidget {
  const StorePopup({
    super.key,
    required this.state,
    required this.onClose,
    required this.onCategorySelected,
    required this.onBuy,
    required this.isOwned,
  });

  final StoreState state;
  final VoidCallback onClose;
  final ValueChanged<StoreCategory> onCategorySelected;
  final ValueChanged<StoreProduct> onBuy;
  final bool Function(StoreProduct product) isOwned;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = math.max(
            160.0,
            math.min(
              math.min(constraints.maxWidth * .94, 520.0),
              constraints.maxHeight * .96 / 1.52,
            ),
          );
          final panelHeight = panelWidth * 1.52;
          final products = StoreCatalog.byCategory(state.selectedCategory);

          return Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              tween: Tween(begin: .90, end: 1),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: SizedBox(
                  width: panelWidth,
                  height: panelHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: panelWidth * .01,
                        width: panelWidth,
                        child: Image.asset(
                          StoreAssets.panel,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: panelWidth * .075,
                        top: 0,
                        width: panelWidth * .85,
                        child: Image.asset(
                          StoreAssets.header,
                          fit: BoxFit.contain,
                        ),
                      ),
                      StoreWallet(
                        panelWidth: panelWidth,
                        coins: state.coins,
                        onPlus: () => onCategorySelected(StoreCategory.coins),
                      ),
                      Positioned(
                        right: -panelWidth * .01,
                        top: panelWidth * .03,
                        width: panelWidth * .14,
                        height: panelWidth * .14,
                        child: GestureDetector(
                          onTap: onClose,
                          child: Image.asset('assets/HUD/close-button.webp'),
                        ),
                      ),
                      StoreTabs(
                        panelWidth: panelWidth,
                        selected: state.selectedCategory,
                        onSelected: onCategorySelected,
                      ),
                      Positioned(
                        left: panelWidth * .076,
                        top: panelWidth * .5058,
                        width: panelWidth * .8502,
                        bottom: panelWidth * .15,
                        child: ClipRect(
                          child: state.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : StoreProductList(
                                  panelWidth: panelWidth,
                                  products: products,
                                  isOwned: isOwned,
                                  canBuy: (product) =>
                                      !state.purchaseInProgress &&
                                      (product.isIap ||
                                          state.coins >= product.price),
                                  onBuy: onBuy,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
