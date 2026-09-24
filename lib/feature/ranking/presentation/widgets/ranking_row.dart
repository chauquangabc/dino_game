import 'package:flutter/material.dart';

import '../../domain/ranking_board.dart';
import '../../domain/ranking_entry.dart';
import 'ranking_assets.dart';

class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.entry,
    required this.board,
    required this.rowHeight,
  });

  final RankingEntry entry;
  final RankingBoard board;
  final double rowHeight;

  String _formatScore(int value) {
    final chars = value.toString().split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) out.add(',');
      out.add(chars[i]);
    }
    return out.reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final compact = board == RankingBoard.weekly;
    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: entry.isCurrentUser
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF32D65A).withValues(alpha: .75),
                          blurRadius: rowHeight * .24,
                        ),
                      ],
                    )
                  : null,
              child: Image.asset(
                RankingAssets.row,
                fit: BoxFit.fill,
                color: entry.isCurrentUser ? const Color(0xFFE9FFE8) : null,
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rowHeight * .05),
            child: Row(
              children: [
                _RankBadge(rank: entry.rank, size: rowHeight * .78),
                SizedBox(width: rowHeight * .035),
                _RankingAvatar(entry: entry, size: rowHeight * .90),
                SizedBox(width: rowHeight * .05),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entry.displayName,
                      maxLines: 1,
                      style: TextStyle(
                        color: entry.isCurrentUser
                            ? const Color(0xFF1F6A22)
                            : const Color(0xFF4A2A0C),
                        fontSize: rowHeight * (compact ? .27 : .31),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: rowHeight * .04),
                _TitleBadge(
                  text: compact
                      ? '${entry.weeklyCompletedLevels} LEVELS'
                      : entry.title,
                  color: entry.titleColor,
                  width: rowHeight * (compact ? 1.22 : 1.38),
                  height: rowHeight * .67,
                ),
                SizedBox(width: rowHeight * .03),
                _ValueBadge(
                  text: compact
                      ? _formatScore(entry.weeklyScore)
                      : 'LV. ${entry.completedLevel}',
                  width: rowHeight * (compact ? 1.15 : .98),
                  height: rowHeight * .49,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.size});
  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(RankingAssets.rank(rank), fit: BoxFit.contain),
        Center(
          child: FractionallySizedBox(
            widthFactor: .46,
            heightFactor: .46,
            child: FittedBox(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Color(0xFFFFF8E6),
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Color(0xFF5B3208), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RankingAvatar extends StatelessWidget {
  const _RankingAvatar({required this.entry, required this.size});
  final RankingEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      children: [
        Positioned(
          left: size * .22,
          top: size * .23,
          width: size * .56,
          height: size * .54,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * .1),
            child: ColoredBox(
              color: const Color(0xFF73C8FA),
              child: Image.asset(entry.avatarAsset, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned.fill(
          child: Image.asset(RankingAssets.avatarFrame, fit: BoxFit.contain),
        ),
      ],
    ),
  );
}

class _TitleBadge extends StatelessWidget {
  const _TitleBadge({
    required this.text,
    required this.color,
    required this.width,
    required this.height,
  });
  final String text;
  final RankingTitleColor color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(RankingAssets.titleBadge(color), fit: BoxFit.fill),
        Padding(
          padding: EdgeInsets.fromLTRB(
            width * .16,
            height * .26,
            width * .16,
            height * .13,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFF8E8),
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFF3C1E06), offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({
    required this.text,
    required this.width,
    required this.height,
  });
  final String text;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(RankingAssets.levelBadge, fit: BoxFit.fill),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * .13,
            vertical: height * .2,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFFFE9B8),
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFF281402), offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
