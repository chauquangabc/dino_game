import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'farm_assets.dart';

class FarmCoinBubble extends StatefulWidget {
  const FarmCoinBubble({
    super.key,
    required this.size,
    required this.drift,
    required this.popping,
    required this.onTap,
    required this.onPopFinished,
  });

  final double size;
  final Offset drift;
  final bool popping;
  final VoidCallback onTap;
  final VoidCallback onPopFinished;

  @override
  State<FarmCoinBubble> createState() => _FarmCoinBubbleState();
}

class _FarmCoinBubbleState extends State<FarmCoinBubble>
    with TickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..forward();
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2700),
  )..repeat();
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onPopFinished();
    });

  @override
  void didUpdateWidget(covariant FarmCoinBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.popping && !oldWidget.popping) {
      _flight.stop();
      _wobble.stop();
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flight.dispose();
    _wobble.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.popping ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flight, _wobble, _pop]),
        builder: (context, child) {
          final travel = Curves.easeOut.transform(_flight.value);
          final appear = (_flight.value / .14).clamp(0.0, 1.0);
          final wobble = reduceMotion
              ? 0.0
              : math.sin(_wobble.value * math.pi * 2);
          final popScale = widget.popping
              ? TweenSequence<double>([
                  TweenSequenceItem(tween: Tween(begin: 1, end: 1.32), weight: 40),
                  TweenSequenceItem(tween: Tween(begin: 1.32, end: 1.7), weight: 60),
                ]).transform(_pop.value)
              : 1.0;
          final popOpacity = widget.popping
              ? TweenSequence<double>([
                  TweenSequenceItem(tween: Tween(begin: 1, end: .75), weight: 45),
                  TweenSequenceItem(tween: Tween(begin: .75, end: 0), weight: 55),
                ]).transform(_pop.value)
              : 1.0;

          return Transform.translate(
            offset: reduceMotion ? Offset.zero : widget.drift * travel,
            child: Opacity(
              opacity: (appear * popOpacity).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: (reduceMotion ? 1.0 : .3 + .7 * appear) * popScale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    1 + wobble * .035,
                    1 - wobble * .035,
                    1,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-.28, -.32),
              radius: .9,
              colors: [Color(0xd9ffffff), Color(0x887cecff), Color(0x665b9eff)],
              stops: [0, .48, 1],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .82),
              width: (widget.size * .035).clamp(1.2, 2.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x553190d0),
                blurRadius: widget.size * .18,
              ),
            ],
          ),
          child: Align(
            alignment: const Alignment(-.1, -.08),
            child: SizedBox.square(
              dimension: widget.size * .52,
              child: Image.asset(FarmAssets.coinIcon, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class FarmCoinPlus extends StatefulWidget {
  const FarmCoinPlus({
    super.key,
    required this.value,
    required this.size,
    required this.onFinished,
  });

  final int value;
  final double size;
  final VoidCallback onFinished;

  @override
  State<FarmCoinPlus> createState() => _FarmCoinPlusState();
}

class _FarmCoinPlusState extends State<FarmCoinPlus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -widget.size * 1.25 * _controller.value),
        child: Opacity(
          opacity: (1 - Curves.easeIn.transform(_controller.value)).clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            FarmAssets.coinIcon,
            width: widget.size * .48,
            height: widget.size * .48,
          ),
          SizedBox(width: widget.size * .06),
          Text(
            '+${widget.value}',
            style: TextStyle(
              color: const Color(0xffffd34f),
              fontSize: widget.size * .38,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Color(0xff5b2500), blurRadius: 2),
                Shadow(color: Colors.black54, offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class FarmToast extends StatelessWidget {
  const FarmToast({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xeb3c2008),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xffffe0a0), width: 2),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xffffe7b3),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
