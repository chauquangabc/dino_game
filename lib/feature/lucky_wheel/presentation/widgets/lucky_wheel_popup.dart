import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/lucky_wheel_catalog.dart';
import '../../domain/lucky_wheel_reward.dart';
import '../../domain/lucky_wheel_state.dart';
import 'lucky_wheel_assets.dart';

class LuckyWheelPopup extends StatelessWidget {
  const LuckyWheelPopup({
    super.key,
    required this.state,
    required this.wheelTurns,
    required this.onClose,
    required this.onSpin,
    required this.onAdSpin,
    required this.onClaim,
  });

  final LuckyWheelState state;
  final double wheelTurns;
  final VoidCallback onClose;
  final VoidCallback onSpin;
  final VoidCallback onAdSpin;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(
            260.0,
            math.min(
              math.min(constraints.maxWidth * .96, 760.0),
              constraints.maxHeight * .96 * 1.5,
            ),
          );
          return Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              tween: Tween(begin: .9, end: 1),
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: SizedBox(
                width: width,
                height: width / 1.5,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        LuckyWheelAssets.panel,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: width * .0529,
                      top: width * .0712,
                      width: width * .5333,
                      height: width * .5333,
                      child: _Wheel(turns: wheelTurns),
                    ),
                    Positioned(
                      left: width * .608,
                      top: width * .0213,
                      width: width * .352,
                      child: Image.asset(LuckyWheelAssets.logo),
                    ),
                    Positioned(
                      left: width * .641,
                      top: width * .1947,
                      width: width * .286,
                      child: _SpinCounter(spins: state.spins),
                    ),
                    Positioned(
                      left: width * .641,
                      top: width * .3058,
                      width: width * .286,
                      child: _ImageButton(
                        asset: LuckyWheelAssets.spinButton,
                        label: 'SPIN',
                        enabled:
                            !state.isLoading &&
                            !state.isSpinning &&
                            state.spins > 0,
                        onTap: onSpin,
                      ),
                    ),
                    Positioned(
                      left: width * .641,
                      top: width * .4112,
                      width: width * .286,
                      child: _ImageButton(
                        asset: LuckyWheelAssets.adButton,
                        label: '+1 SPIN',
                        enabled: !state.isSpinning,
                        small: true,
                        onTap: onAdSpin,
                      ),
                    ),
                    Positioned(
                      left: width * .641,
                      top: width * .5174,
                      width: width * .286,
                      child: _Streak(day: state.streakDay),
                    ),
                    Positioned(
                      left: width * .922,
                      top: width * .009,
                      width: width * .078,
                      height: width * .078,
                      child: GestureDetector(
                        onTap: state.isSpinning ? null : onClose,
                        child: Image.asset('assets/HUD/close-button.webp'),
                      ),
                    ),
                    if (state.isLoading)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (state.message != null)
                      Positioned(
                        left: width * .18,
                        right: width * .18,
                        bottom: width * .025,
                        child: _Toast(text: state.message!),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.turns});

  static const _rotationOrigin = Alignment(-.0012, -.0556);

  final double turns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => TweenAnimationBuilder<double>(
        duration: LuckyWheelCatalog.spinDuration,
        curve: Curves.easeOutQuart,
        tween: Tween(end: turns),
        builder: (context, angle, wheel) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.rotate(
                angle: angle * math.pi * 2,
                alignment: _rotationOrigin,
                child: wheel,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -constraints.maxWidth * .162,
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: .241,
                  child: _WheelPointer(wheelTurns: angle),
                ),
              ),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(LuckyWheelAssets.wheel, fit: BoxFit.fill),
            for (var i = 0; i < LuckyWheelCatalog.rewards.length; i++)
              _SegmentIcon(index: i, reward: LuckyWheelCatalog.rewards[i]),
          ],
        ),
      ),
    );
  }
}

class _WheelPointer extends StatelessWidget {
  const _WheelPointer({required this.wheelTurns});

  final double wheelTurns;

  @override
  Widget build(BuildContext context) {
    final segmentProgress =
        ((wheelTurns * LuckyWheelCatalog.rewards.length + .5) % 1 + 1) % 1;
    final easedProgress = Curves.easeIn.transform(segmentProgress);
    final pointerTurns = MediaQuery.disableAnimationsOf(context)
        ? 0.0
        : -13 / 360 * easedProgress;

    return Transform.rotate(
      angle: pointerTurns * math.pi * 2,
      alignment: const Alignment(0, -.44),
      child: Image.asset(LuckyWheelAssets.pointer),
    );
  }
}

class _SegmentIcon extends StatelessWidget {
  const _SegmentIcon({required this.index, required this.reward});

  static const _itemFactor = .17;
  static const _alignmentRadius = .7554216867;
  static const _alignmentCenterX = -.0014457831;
  static const _alignmentCenterY = -.0669879518;

  final int index;
  final LuckyWheelReward reward;

  @override
  Widget build(BuildContext context) {
    final angle = index * math.pi / 4;
    return Align(
      alignment: Alignment(
        _alignmentCenterX + math.sin(angle) * _alignmentRadius,
        _alignmentCenterY - math.cos(angle) * _alignmentRadius,
      ),
      child: Transform.rotate(
        angle: angle,
        child: FractionallySizedBox(
          widthFactor: _itemFactor,
          heightFactor: _itemFactor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Transform.scale(
                  scale: 1.5,
                  child: Image.asset(reward.assetPath, fit: BoxFit.contain),
                ),
              ),
              FittedBox(
                child: Text(
                  'x${reward.quantity}',
                  style: const TextStyle(
                    color: Color(0xFFFFF4D6),
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0xFF5A2D08),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinCounter extends StatelessWidget {
  const _SpinCounter({required this.spins});

  final int spins;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1983 / 793,
    child: LayoutBuilder(
      builder: (context, constraints) {
        const eggCenters = [.2573, .5008, .7442];
        final panelWidth = constraints.maxWidth;
        final panelHeight = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(LuckyWheelAssets.spinsPanel, fit: BoxFit.fill),
            ),
            for (var i = 0; i < math.min(spins, eggCenters.length); i++)
              Positioned(
                left: panelWidth * eggCenters[i],
                top: panelHeight * .545,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: SizedBox(
                    width: panelWidth * .19,
                    child: Image.asset(
                      LuckyWheelAssets.spinEgg,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (spins > eggCenters.length)
              Positioned(
                left: panelWidth * .89,
                top: panelHeight * .52,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: _CountBubble(count: spins, size: panelHeight * .38),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD257),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF7A4A10), width: size * .06),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            offset: Offset(0, size * .08),
            blurRadius: size * .16,
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.all(size * .16),
            child: Text(
              '$count',
              style: TextStyle(
                color: const Color(0xFF5A2E08),
                fontSize: size * .62,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Streak extends StatelessWidget {
  const _Streak({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2172 / 724,
    child: LayoutBuilder(
      builder: (context, constraints) {
        const eggCenters = [.1693, .2797, .39, .5002, .6105, .7208, .8311];
        final panelWidth = constraints.maxWidth;
        final panelHeight = constraints.maxHeight;
        final visibleEggs = day.clamp(0, eggCenters.length);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                LuckyWheelAssets.streakPanel,
                fit: BoxFit.fill,
              ),
            ),
            for (var i = 0; i < visibleEggs; i++)
              Positioned(
                left: panelWidth * eggCenters[i],
                top: panelHeight * .49,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: SizedBox(
                    width: panelWidth * .108,
                    child: Image.asset(
                      LuckyWheelAssets.streakEgg,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ImageButton extends StatelessWidget {
  const _ImageButton({
    required this.asset,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.small = false,
  });

  final String asset;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .55,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(asset),
          Positioned.fill(
            left: 10,
            right: 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFFFF8E6),
                  fontSize: small ? 16 : 20,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF7A3A0A),
                      offset: Offset(0, 2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.result,
    required this.isClaiming,
    required this.onClaim,
  });

  final LuckyWheelResult result;
  final bool isClaiming;
  final VoidCallback onClaim;

  static const _cardRatio = 1.202;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const ColoredBox(color: Color(0xA3080C18)),
        ),
      ),
      Positioned.fill(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.min(
                math.min(constraints.maxWidth * .82, 420.0),
                constraints.maxHeight * .9 / _cardRatio,
              );
              final cardHeight = cardWidth * _cardRatio;

              return Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  tween: Tween(begin: .9, end: 1),
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            LuckyWheelAssets.rewardPanel,
                            fit: BoxFit.fill,
                          ),
                        ),
                        Positioned(
                          left: cardWidth * .14,
                          top: cardWidth * .083,
                          width: cardWidth * .72,
                          height: cardWidth * .72 * 749 / 2098,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                LuckyWheelAssets.rewardTitle,
                                fit: BoxFit.fill,
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  cardWidth * .05,
                                  cardWidth * .018,
                                  cardWidth * .05,
                                  cardWidth * .022,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'YOU WON',
                                    style: TextStyle(
                                      color: const Color(0xFFFFF7E6),
                                      fontSize: cardWidth * .078,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF7A3A0A),
                                          offset: Offset(0, cardWidth * .009),
                                          blurRadius: cardWidth * .006,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: cardWidth * .25,
                          top: cardWidth * .31,
                          width: cardWidth * .5,
                          height: cardWidth * .5,
                          child: const _RewardBurst(),
                        ),
                        Positioned(
                          left: cardWidth * .29,
                          top: cardWidth * .33,
                          width: cardWidth * .42,
                          height: cardWidth * .42 * 1305 / 1206,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  LuckyWheelAssets.rewardItemPanel,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              Positioned(
                                left: cardWidth * .42 * .2035,
                                right: cardWidth * .42 * .2185,
                                top: cardWidth * .42 * 1305 / 1206 * .122,
                                height: cardWidth * .42 * 1305 / 1206 * .416,
                                child: Image.asset(
                                  result.reward.assetPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: cardWidth * .28,
                          right: cardWidth * .28,
                          top: cardWidth * .63,
                          height: cardWidth * .09,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'x${result.reward.quantity}',
                              style: TextStyle(
                                color: const Color(0xFF7A4413),
                                fontSize: cardWidth * .062,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66FFFFFF),
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: cardWidth * .12,
                          right: cardWidth * .12,
                          top: cardWidth * .795,
                          height: cardWidth * .07,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              result.reward.name,
                              style: TextStyle(
                                color: const Color(0xFF7A4413),
                                fontSize: cardWidth * .052,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: .7),
                                    offset: Offset(0, cardWidth * .003),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: cardWidth * .25,
                          top: cardWidth * .885,
                          width: cardWidth * .5,
                          child: _ImageButton(
                            asset: LuckyWheelAssets.claimButton,
                            label: isClaiming ? 'CLAIMING...' : 'CLAIM',
                            enabled: !isClaiming,
                            onTap: onClaim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

class _RewardBurst extends StatefulWidget {
  const _RewardBurst();

  @override
  State<_RewardBurst> createState() => _RewardBurstState();
}

class _RewardBurstState extends State<_RewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    clipBehavior: Clip.none,
    children: [
      FractionallySizedBox(
        widthFactor: 1.9,
        heightFactor: 1.9,
        child: RotationTransition(
          turns: _controller,
          child: CustomPaint(painter: const _RewardRaysPainter()),
        ),
      ),
      FractionallySizedBox(
        widthFactor: 1.7,
        heightFactor: 1.7,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xF2FFF0AA), Color(0x99FFC446), Color(0x00FFAA28)],
              stops: [0, .32, .68],
            ),
          ),
        ),
      ),
    ],
  );
}

class _RewardRaysPainter extends CustomPainter {
  const _RewardRaysPainter();

  static const _rayCount = 15;
  static const _raySweep = math.pi / 20;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .5;
    final innerRadius = radius * .2;
    final outerRadius = radius * .7;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x8CFFE178), Color(0x00FFE178)],
        stops: [.2, .7],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (var i = 0; i < _rayCount; i++) {
      final start = i * math.pi * 2 / _rayCount;
      final path = Path()
        ..moveTo(
          center.dx + math.cos(start) * innerRadius,
          center.dy + math.sin(start) * innerRadius,
        )
        ..lineTo(
          center.dx + math.cos(start) * outerRadius,
          center.dy + math.sin(start) * outerRadius,
        )
        ..lineTo(
          center.dx + math.cos(start + _raySweep) * outerRadius,
          center.dy + math.sin(start + _raySweep) * outerRadius,
        )
        ..lineTo(
          center.dx + math.cos(start + _raySweep) * innerRadius,
          center.dy + math.sin(start + _raySweep) * innerRadius,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RewardRaysPainter oldDelegate) => false;
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xE6141E28),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFFFE9A8),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
