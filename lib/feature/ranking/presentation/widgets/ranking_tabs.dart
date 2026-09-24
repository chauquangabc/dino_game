import 'package:flutter/material.dart';

import '../../domain/ranking_board.dart';
import 'ranking_assets.dart';

class RankingTabs extends StatelessWidget {
  const RankingTabs({
    super.key,
    required this.panelWidth,
    required this.selected,
    required this.onSelected,
  });

  final double panelWidth;
  final RankingBoard selected;
  final ValueChanged<RankingBoard> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final board in RankingBoard.values) ...[
        if (board.index > 0) SizedBox(width: panelWidth * .012),
        Expanded(
          child: _RankingTab(
            board: board,
            selected: board == selected,
            onTap: () => onSelected(board),
          ),
        ),
      ],
    ],
  );
}

class _RankingTab extends StatelessWidget {
  const _RankingTab({
    required this.board,
    required this.selected,
    required this.onTap,
  });

  final RankingBoard board;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4.25,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * (selected ? -.0263 : -.0848),
                right: width * (selected ? -.0263 : -.0848),
                top: height * (selected ? -.2623 : -.2942),
                bottom: height * (selected ? -.3275 : -.2764),
                child: Image.asset(
                  selected
                      ? RankingAssets.tabActive
                      : RankingAssets.tabInactive,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: width * (selected ? .24 : .28),
                right: width * .06,
                top: height * .11,
                bottom: height * .11,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    board.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: width,
                      color: selected
                          ? const Color(0xFFFFF7E4)
                          : const Color(0xFFF4E6C9),
                      fontWeight: FontWeight.w900,
                      letterSpacing: width * .003,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
