import 'package:flutter/material.dart';

import '../../domain/store_product.dart';
import 'store_product_row.dart';

class StoreProductList extends StatelessWidget {
  const StoreProductList({
    super.key,
    required this.panelWidth,
    required this.products,
    required this.isOwned,
    required this.canBuy,
    required this.onBuy,
  });

  final double panelWidth;
  final List<StoreProduct> products;
  final bool Function(StoreProduct product) isOwned;
  final bool Function(StoreProduct product) canBuy;
  final ValueChanged<StoreProduct> onBuy;

  @override
  Widget build(BuildContext context) {
    final width = panelWidth * .8502;
    final rowHeight = width / (2172 / 724);
    final overlap = panelWidth * .0735;
    final slotHeight = rowHeight - overlap;

    return ListView.builder(
      padding: EdgeInsets.only(bottom: panelWidth * .02 + overlap),
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      itemExtent: slotHeight,
      itemBuilder: (context, index) {
        final product = products[index];
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: rowHeight,
          maxHeight: rowHeight,
          child: StoreProductRow(
            product: product,
            panelWidth: panelWidth,
            owned: isOwned(product),
            enabled: canBuy(product),
            onBuy: () => onBuy(product),
          ),
        );
      },
    );
  }
}
