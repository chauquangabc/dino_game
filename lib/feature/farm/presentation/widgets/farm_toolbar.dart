import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/farm_catalog.dart';
import '../../domain/farm_state.dart';
import 'farm_assets.dart';

class FarmToolbar extends StatelessWidget {
  const FarmToolbar({
    super.key,
    required this.viewport,
    required this.safeTop,
    required this.state,
    required this.busy,
    required this.onFeed,
    required this.onClaim,
    required this.onPets,
    required this.onClose,
  });

  final Size viewport;
  final double safeTop;
  final FarmState state;
  final bool busy;
  final VoidCallback onFeed, onClaim, onPets, onClose;

  static const _feed = _AssetRatio(3, .9282);
  static const _claim = _AssetRatio(2.6532, .8728);
  static const _coins = _AssetRatio(3, .7597);

  @override
  Widget build(BuildContext context) {
    final width = viewport.width, height = viewport.height;
    final gap = math.max(6.0, math.min(width, height) * .022);
    const widthFactor = 10.2207;
    var bodyHeight = math.min(
      height * .11,
      (width * .94 - gap * 2) / widthFactor,
    );
    bodyHeight = bodyHeight.clamp(20.0, 60.0);
    final feedSize = _feed.sizeFor(bodyHeight);
    final claimSize = _claim.sizeFor(bodyHeight);
    final coinSize = _coins.sizeFor(bodyHeight);
    final groupWidth =
        feedSize.width + claimSize.width + coinSize.width + gap * 2;
    final visibleTop = safeTop + height * .05;
    final rowHeight = coinSize.height;
    final groupTop = visibleTop - (rowHeight - bodyHeight) / 2;

    final padding = math.max(6.0, math.min(width, height) * .02);
    final closeSize = bodyHeight * 1.25 / .8756;
    final sideSpace = (width - groupWidth) / 2;
    final sideTop = sideSpace > closeSize + padding
        ? visibleTop + bodyHeight / 2 - closeSize / 2
        : visibleTop + bodyHeight + padding;
    final petSize = closeSize * .8756 / .9689;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            left: (width - groupWidth) / 2,
            top: groupTop,
            width: groupWidth,
            height: rowHeight,
            child: Row(
              children: [
                SizedBox.fromSize(
                  size: feedSize,
                  child: _ImageButton(
                    asset: FarmAssets.feedButton,
                    label: 'FEED',
                    onTap: onFeed,
                  ),
                ),
                SizedBox(width: gap),
                SizedBox.fromSize(
                  size: claimSize,
                  child: _ImageButton(
                    asset: FarmAssets.claimButton,
                    label: 'CLAIM',
                    onTap: state.pendingCoins > 0 && !busy ? onClaim : null,
                  ),
                ),
                SizedBox(width: gap),
                SizedBox.fromSize(
                  size: coinSize,
                  child: _CoinPanel(state: state),
                ),
              ],
            ),
          ),
          Positioned(
            left: padding,
            top: sideTop + (closeSize - petSize) / 2,
            width: petSize,
            height: petSize,
            child: _IconButton(
              asset: FarmAssets.petButton,
              tooltip: 'My dinos',
              onTap: onPets,
            ),
          ),
          Positioned(
            right: padding,
            top: sideTop,
            width: closeSize,
            height: closeSize,
            child: _IconButton(
              asset: FarmAssets.closeButton,
              tooltip: 'Close',
              onTap: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageButton extends StatelessWidget {
  const _ImageButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset, label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .55 : 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill)),
            FractionallySizedBox(
              widthFactor: .64,
              heightFactor: .43,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xaa542200), offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.asset,
    required this.tooltip,
    required this.onTap,
  });

  final String asset, tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    ),
  );
}

class _CoinPanel extends StatelessWidget {
  const _CoinPanel({required this.state});

  final FarmState state;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Image.asset(FarmAssets.coinPanel, fit: BoxFit.fill),
      ),
      Align(
        alignment: const Alignment(-.65, -.25),
        child: FractionallySizedBox(
          heightFactor: .34,
          child: FittedBox(child: Image.asset(FarmAssets.coinIcon)),
        ),
      ),
      _PanelText(
        alignment: const Alignment(-.74, .4),
        width: .22,
        height: .22,
        text: '${state.coins}',
      ),
      _PanelText(
        alignment: const Alignment(.48, .03),
        width: .58,
        height: .26,
        text: '${FarmCatalog.coinsPerHour} COINS / HOUR',
        secondary: true,
      ),
    ],
  );
}

class _PanelText extends StatelessWidget {
  const _PanelText({
    required this.alignment,
    required this.width,
    required this.height,
    required this.text,
    this.secondary = false,
  });

  final Alignment alignment;
  final double width, height;
  final String text;
  final bool secondary;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: FractionallySizedBox(
      widthFactor: width,
      heightFactor: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            color: secondary
                ? const Color(0xff8b5a2c)
                : const Color(0xff6b3b13),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

class _AssetRatio {
  const _AssetRatio(this.aspect, this.visibleHeight);

  final double aspect, visibleHeight;

  Size sizeFor(double bodyHeight) {
    final height = bodyHeight / visibleHeight;
    return Size(height * aspect, height);
  }
}
