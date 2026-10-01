import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/farm_catalog.dart';
import '../../domain/farm_food.dart';
import '../../domain/farm_state.dart';
import 'farm_assets.dart';

class FarmFoodTray extends StatelessWidget {
  const FarmFoodTray({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onFeed,
    required this.onDragStarted,
  });

  final FarmState state;
  final ValueChanged<FarmFood> onSelect;
  final ValueChanged<FarmFood> onFeed;
  final VoidCallback onDragStarted;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, viewport) {
        final landscape = viewport.maxWidth > viewport.maxHeight * 1.15;
        final trayWidth = landscape
            ? math.min(viewport.maxWidth * .26, 440.0)
            : math.min(
                math.min(viewport.maxWidth * .92, viewport.maxHeight * 1.05),
                520.0,
              );
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: trayWidth,
            child: AspectRatio(
              aspectRatio: 2,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(FarmAssets.foodTray, fit: BoxFit.fill),
                    ),
                    Align(
                      alignment: const Alignment(0, -.72),
                      child: FractionallySizedBox(
                        widthFactor: .36,
                        heightFactor: .13,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PICK A TREAT!',
                            style: TextStyle(
                              color: const Color(0xff704018),
                              fontSize: constraints.maxHeight * .08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * .059,
                      right: constraints.maxWidth * .059,
                      top: constraints.maxHeight * .31,
                      height: constraints.maxHeight * .59,
                      child: Row(
                        children: [
                          for (
                            var i = 0;
                            i < FarmCatalog.foods.length;
                            i++
                          ) ...[
                            if (i > 0)
                              SizedBox(width: constraints.maxWidth * .018),
                            Expanded(
                              child: FarmFoodCell(
                                food: FarmCatalog.foods[i],
                                count:
                                    state.foodInventory[FarmCatalog
                                        .foods[i]
                                        .id] ??
                                    0,
                                selected:
                                    state.selectedFoodId ==
                                    FarmCatalog.foods[i].id,
                                onSelect: () => onSelect(FarmCatalog.foods[i]),
                                onFeed: () => onFeed(FarmCatalog.foods[i]),
                                onDragStarted: onDragStarted,
                              ),
                            ),
                          ],
                        ],
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

class FarmFoodCell extends StatelessWidget {
  const FarmFoodCell({
    super.key,
    required this.food,
    required this.count,
    required this.selected,
    required this.onSelect,
    required this.onFeed,
    required this.onDragStarted,
  });

  final FarmFood food;
  final int count;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onFeed;
  final VoidCallback onDragStarted;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxWidth;
        return Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * .05,
              right: constraints.maxWidth * .05,
              top: constraints.maxHeight * .03,
              height: constraints.maxHeight * .6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(unit * .075),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: selected
                        ? const [Color(0xffffef9c), Color(0xff9bdc69)]
                        : const [Color(0xffd8f4dc), Color(0xff8fcf86)],
                  ),
                  border: Border.all(
                    color: selected
                        ? const Color(0xffffdf4d)
                        : const Color(0x8890bd73),
                    width: unit * .012,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x552b5a28),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -1.2),
              child: FractionallySizedBox(
                widthFactor: .76,
                heightFactor: .62,
                child: Padding(
                  padding: EdgeInsets.all(unit * .045),
                  child: Image.asset(food.assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.1),
              child: FractionallySizedBox(
                widthFactor: .8,
                heightFactor: .16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    food.name,
                    style: const TextStyle(
                      color: Color(0xffffe2a2),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, .52),
              child: FractionallySizedBox(
                widthFactor: .55,
                heightFactor: .13,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${food.duration.inHours}H',
                    style: const TextStyle(
                      color: Color(0xffffe2a2),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, .88),
              child: FractionallySizedBox(
                widthFactor: .55,
                heightFactor: .13,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'x$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    return FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onFeed();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: '${food.name}, $count available',
        child: GestureDetector(
          onTap: onSelect,
          child: count > 0
              ? Draggable<FarmFood>(
                  data: food,
                  onDragStarted: onDragStarted,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).shortestSide * .24,
                      height: MediaQuery.sizeOf(context).shortestSide * .24,
                      child: Image.asset(food.assetPath, fit: BoxFit.contain),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .35, child: content),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
