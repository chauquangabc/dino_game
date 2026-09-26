import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/ranking_board.dart';
import '../../domain/ranking_state.dart';
import 'ranking_assets.dart';
import 'ranking_list.dart';
import 'ranking_tabs.dart';

class RankingPopup extends StatelessWidget {
  const RankingPopup({
    super.key,
    required this.state,
    required this.onBoardSelected,
    required this.onClose,
  });

  static const panelRatio = 1402 / 1122;

  final RankingState state;
  final ValueChanged<RankingBoard> onBoardSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Width drives every child dimension, just like StorePopup. Keeping
        // the height-derived limit in the same calculation prevents overflow
        // in landscape and on devices with a short safe area.
        final panelWidth = math.min(
          math.min(constraints.maxWidth * .94, 560.0),
          constraints.maxHeight * .95 / panelRatio,
        );
        final panelHeight = panelWidth * panelRatio;

        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .93, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(RankingAssets.panel, fit: BoxFit.fill),
                  ),
                  Positioned(
                    left: panelWidth * .18,
                    top: panelWidth * .08,
                    width: panelWidth * .64,
                    height: panelWidth * .09,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            RankingAssets.titleHeader,
                            fit: BoxFit.fill,
                          ),
                        ),
                        Positioned(
                          left: -panelWidth * .008,
                          right: -panelWidth * .008,
                          top: -panelWidth * .041,
                          bottom: -panelWidth * .041,
                          child: Image.asset(
                            RankingAssets.titleText,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: panelWidth * .855,
                    top: panelWidth * .026,
                    width: panelWidth * .13,
                    height: panelWidth * .13,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      child: Image.asset(
                        'assets/HUD/close-button.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: panelWidth * .136,
                    top: panelWidth * .16,
                    width: panelWidth * .728,
                    child: RankingTabs(
                      panelWidth: panelWidth,
                      selected: state.selectedBoard,
                      onSelected: onBoardSelected,
                    ),
                  ),
                  Positioned(
                    left: panelWidth * .136,
                    top: panelWidth * .2405,
                    width: panelWidth * .728,
                    // CSS uses 59.95% of the panel height (about .749 of its
                    // width), which fits six .1244-wide rows exactly.
                    height: panelHeight * .65,
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: RankingList(
                          key: ValueKey(state.selectedBoard),
                          entries: state.visibleEntries,
                          board: state.selectedBoard,
                          // Matches the HTML layout: six rows sit flush inside
                          // the list viewport with no vertical gap.
                          rowHeight: panelWidth * .15,
                        ),
                      ),
                    ),
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
