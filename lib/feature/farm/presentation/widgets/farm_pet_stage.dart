import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/farm_food.dart';
import '../../domain/farm_mood.dart';

class FarmPetStage extends StatelessWidget {
  const FarmPetStage({
    super.key,
    required this.rect,
    required this.assetPath,
    required this.health,
    required this.mood,
    required this.bounce,
    required this.hovered,
    required this.onTap,
    required this.onHoverChanged,
    required this.onFoodDropped,
  });

  final Rect rect;
  final String assetPath;
  final double health;
  final FarmMood mood;
  final Animation<double> bounce;
  final bool hovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverChanged;
  final ValueChanged<FarmFood> onFoodDropped;

  @override
  Widget build(BuildContext context) {
    final dropRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 1.22,
      height: rect.height * 1.22,
    );
    return Positioned.fromRect(
      rect: dropRect,
      child: DragTarget<FarmFood>(
        onWillAcceptWithDetails: (_) {
          onHoverChanged(true);
          return true;
        },
        onLeave: (_) => onHoverChanged(false),
        onAcceptWithDetails: (details) {
          onHoverChanged(false);
          onFoodDropped(details.data);
        },
        builder: (context, candidates, rejected) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: rect.width * .11,
              vertical: rect.height * .11,
            ),
            child: AnimatedBuilder(
              animation: bounce,
              builder: (context, child) => Transform.scale(
                scale:
                    1 +
                    math.sin(bounce.value * math.pi) * .10 +
                    (hovered ? .08 : 0),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: rect.height * 1.02,
                    width: math.max(72, rect.width * .72),
                    child: FarmHealthBar(
                      value: health,
                      mood: mood,
                      height: (rect.width * .075).clamp(8, 16),
                    ),
                  ),
                  Positioned.fill(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FarmHealthBar extends StatelessWidget {
  const FarmHealthBar({
    super.key,
    required this.value,
    required this.mood,
    required this.height,
  });
  final double value;
  final FarmMood mood;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: EdgeInsets.all((height * .14).clamp(1, 2)),
    decoration: BoxDecoration(
      color: const Color(0x99341c08),
      borderRadius: BorderRadius.circular(99),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.transparent,
        color: switch (mood) {
          FarmMood.happy => const Color(0xff4fbf16),
          FarmMood.normal => const Color(0xfff2c31a),
          FarmMood.hungry => const Color(0xffe33c22),
        },
      ),
    ),
  );
}
