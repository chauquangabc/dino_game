import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/chest_catalog.dart';
import '../../domain/chest_reward.dart';

class ChestOpeningPopup extends StatefulWidget {
  const ChestOpeningPopup({
    super.key,
    required this.result,
    required this.remaining,
    required this.busy,
    required this.onAgain,
    required this.onClose,
  });

  final ChestOpeningResult result;
  final int remaining;
  final bool busy;
  final VoidCallback onAgain, onClose;

  @override
  State<ChestOpeningPopup> createState() => _ChestOpeningPopupState();
}

class _ChestOpeningPopupState extends State<ChestOpeningPopup>
    with SingleTickerProviderStateMixin {
  static const _root = 'assets/store/chests';
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1530),
  );
  bool _claimed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
    } else {
      _animation.forward();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.busy ? null : widget.onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: const ColoredBox(color: Color(0xa0080c18)),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = math.min(
                520.0,
                math.min(
                  constraints.maxWidth * .9,
                  constraints.maxHeight * .9 / 1.202,
                ),
              );
              final d = ChestCatalog.byId(widget.result.chestId)!;
              return Center(
                child: SizedBox(
                  width: w,
                  height: w * 1.202,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (_, _) {
                      final open = _animation.value >= .4;
                      final revealed = _animation.value >= .72;
                      final busy = widget.busy || !_animation.isCompleted;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              '$_root/opening-panel.webp',
                              fit: BoxFit.fill,
                            ),
                          ),
                          Positioned(
                            left: w * .08,
                            right: w * .08,
                            top: w * .02,
                            height: w * .20,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  '$_root/opening-header.webp',
                                  fit: BoxFit.contain,
                                ),
                                const Center(
                                  child: FractionallySizedBox(
                                    widthFactor: .7,
                                    heightFactor: .5,
                                    child: FittedBox(
                                      child: Text(
                                        'REWARDS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: w * .28,
                            top: w * .24,
                            width: w * .44,
                            height: w * .36,
                            child: Transform.rotate(
                              angle: open
                                  ? 0
                                  : math.sin(_animation.value * 70) * .07,
                              child: Image.asset(
                                open ? d.openAsset : d.asset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            left: w * .07,
                            right: w * .07,
                            top: w * .60,
                            height: w * .28,
                            child: AnimatedOpacity(
                              opacity: revealed ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: widget.result.rewards
                                    .map(
                                      (r) => SizedBox(
                                        width:
                                            w *
                                            math.min(
                                              .26,
                                              .86 /
                                                  widget.result.rewards.length,
                                            ),
                                        child: _reward(r),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: w * .1,
                            right: w * .1,
                            top: w * .885,
                            height: w * .045,
                            child: FittedBox(
                              child: Text(
                                widget.remaining > 0
                                    ? 'Chests left: ${widget.remaining}'
                                    : 'No chests left',
                                style: const TextStyle(
                                  color: Color(0xff7a4413),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          _button(
                            w,
                            .1763,
                            'opening-again.webp',
                            'OPEN AGAIN',
                            !busy && widget.remaining > 0
                                ? widget.onAgain
                                : null,
                          ),
                          _button(
                            w,
                            .5147,
                            'opening-claim.webp',
                            _claimed ? 'DONE' : 'CLAIM',
                            busy
                                ? null
                                : () {
                                    if (_claimed) {
                                      widget.onClose();
                                    } else {
                                      setState(() => _claimed = true);
                                    }
                                  },
                          ),
                          Positioned(
                            left: w * .87,
                            top: w * .075,
                            width: w * .13,
                            height: w * .13,
                            child: GestureDetector(
                              key: const ValueKey('chest-close'),
                              onTap: widget.busy ? null : widget.onClose,
                              child: Image.asset('$_root/opening-close.webp'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _reward(ChestReward reward) => Semantics(
    label: '${reward.name} x${reward.quantity}',
    child: Tooltip(
      message: reward.name,
      child: AspectRatio(
        aspectRatio: 1206 / 1305,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('$_root/reward-slot.webp', fit: BoxFit.fill),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: const Alignment(0, -.55),
                widthFactor: .58,
                heightFactor: .416,
                child: Image.asset(reward.asset, fit: BoxFit.contain),
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: const Alignment(0, .62),
                widthFactor: .7,
                heightFactor: .23,
                child: FittedBox(
                  child: Text(
                    'x${reward.quantity}',
                    style: const TextStyle(
                      color: Color(0xff7a4413),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _button(
    double w,
    double x,
    String asset,
    String label,
    VoidCallback? onTap,
  ) => Positioned(
    left: w * x,
    top: w * .9493,
    width: w * .309,
    height: w * .1165,
    child: Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        key: ValueKey('chest-$label'),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .5 : 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('$_root/$asset', fit: BoxFit.fill),
              Center(
                child: FractionallySizedBox(
                  widthFactor: .76,
                  heightFactor: .413,
                  child: FittedBox(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
