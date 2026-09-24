import 'package:flutter/material.dart';

import 'store_assets.dart';

class StoreWallet extends StatelessWidget {
  const StoreWallet({
    super.key,
    required this.panelWidth,
    required this.coins,
    required this.onPlus,
  });

  final double panelWidth;
  final int coins;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final width = panelWidth * .30;
    final height = width * 768 / 2048;
    return Positioned(
      left: 0,
      top: panelWidth * .045,
      width: width,
      child: AspectRatio(
        aspectRatio: 2048 / 768,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(StoreAssets.wallet, fit: BoxFit.fill),
            ),
            Positioned(
              left: width * .33,
              right: width * .16,
              top: height * .27,
              bottom: height * .30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _format(coins),
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFFFFE7B3),
                    fontSize: panelWidth * .048,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(color: Color(0xFF3A1A00), offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -width * .04,
              top: (height - width * .24) / 2,
              width: width * .24,
              height: width * .24,
              child: GestureDetector(
                onTap: onPlus,
                child: Image.asset(StoreAssets.plus, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
