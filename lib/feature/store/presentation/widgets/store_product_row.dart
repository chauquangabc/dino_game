import 'package:flutter/material.dart';

import '../../domain/store_product.dart';
import 'store_assets.dart';

class StoreProductRow extends StatelessWidget {
  const StoreProductRow({
    super.key,
    required this.product,
    required this.panelWidth,
    required this.owned,
    required this.enabled,
    required this.onBuy,
  });

  final StoreProduct product;
  final double panelWidth;
  final bool owned;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final rowWidth = panelWidth * .8502;
    final rowHeight = rowWidth / (2172 / 724);
    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(StoreAssets.productRow, fit: BoxFit.fill),
          ),
          Positioned(
            left: rowWidth * .045,
            top: rowHeight * .18,
            width: rowWidth * .24,
            height: rowHeight * .6,
            child: Image.asset(product.assetPath, fit: BoxFit.contain),
          ),
          Positioned(
            left: rowWidth * .315,
            top: rowHeight * .19,
            width: rowWidth * .385,
            bottom: rowHeight * .16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.name,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF5A3413),
                        fontSize: panelWidth * .035,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: panelWidth * .006),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF4D6).withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(panelWidth * .012),
                    border: Border.all(color: const Color(0x66A0783C)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: panelWidth * .016,
                      vertical: panelWidth * .004,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        owned ? 'OWNED' : 'x${product.quantity}',
                        maxLines: 1,
                        style: TextStyle(
                          color: owned
                              ? const Color(0xFF8A6A2A)
                              : const Color(0xFF5D9A1D),
                          fontSize: panelWidth * .036,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: rowWidth * .035,
            top: rowHeight * .25,
            width: rowWidth * .275,
            height: rowHeight * .50,
            child: GestureDetector(
              onTap: enabled && !owned ? onBuy : null,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      enabled && !owned
                          ? StoreAssets.buyNormal
                          : StoreAssets.buyDisabled,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: panelWidth * .05,
                    right: panelWidth * .008,
                    top: rowHeight * .05,
                    bottom: rowHeight * .06,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        owned ? 'OWNED' : _priceText(product),
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: owned
                              ? panelWidth * .03
                              : panelWidth * .038,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _priceText(StoreProduct product) {
    if (product.isIap) return '\$${product.price.toStringAsFixed(2)}';
    return _formatNumber(product.price.toInt());
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
