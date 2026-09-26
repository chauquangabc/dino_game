import 'dart:math' as math;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Prevent taller rows from making their horizontal content wider than
        // the list viewport. The background can still use the full rowHeight.
        final contentHeight = math.min(rowHeight, constraints.maxWidth / 5.15);

        return SizedBox(
          height: rowHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: entry.isCurrentUser
                      ? ShapeDecoration(
                          // Dùng BeveledRectangleBorder để cắt vát chéo 4 góc phẳng theo đúng viền đá
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              rowHeight * 0.28,
                            ), // Điều chỉnh độ sâu của góc vát
                          ),
                          shadows: [
                            // Lớp 1: Ánh sáng lan toả rộng, mờ ảo ra xung quanh
                            BoxShadow(
                              color: const Color(
                                0xFF32D65A,
                              ).withValues(alpha: 0.6),
                              blurRadius: rowHeight * 0.35,
                              spreadRadius: 2.0,
                            ),
                            // Lớp 2: Ánh sáng gắt và sáng sát mép thanh đá
                            BoxShadow(
                              color: const Color(
                                0xFF69F0AE,
                              ).withValues(alpha: 0.8),
                              blurRadius: rowHeight * 0.15,
                              spreadRadius: 0.5,
                            ),
                          ],
                        )
                      : null,
                  // row-blank.webp is 1000x333, but its visible horizontal bar
                  // only occupies y=81..242. Crop those transparent top and
                  // bottom bands, then stretch the actual bar to rowHeight.
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: -rowHeight * (81 / 161),
                          height: rowHeight * (333 / 161),
                          child: Image.asset(
                            RankingAssets.row,
                            fit: BoxFit.fill,
                            color: entry.isCurrentUser
                                ? const Color(0xFFE9FFE8)
                                : null,
                            colorBlendMode: BlendMode.modulate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: contentHeight * .3),
                  child: Row(
                    children: [
                      _RankBadge(rank: entry.rank, size: contentHeight * .6),
                      SizedBox(width: contentHeight * 0.001),
                      _RankingAvatar(entry: entry, size: contentHeight * .85),
                      SizedBox(width: contentHeight * .05),
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
                              fontSize: contentHeight * .27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (compact) ...[
                        SizedBox(width: contentHeight * .04),
                        _TitleBadge(
                          text: entry.title,
                          color: entry.titleColor,
                          width: contentHeight * 1.22,
                          height: contentHeight * .67,
                        ),
                      ],
                      SizedBox(width: contentHeight * .03),
                      if (compact)
                        _ValueBadge(
                          text: 'LV. ${entry.completedLevel}',
                          width: contentHeight,
                          height: contentHeight * .49,
                        )
                      else
                        _ProgressValue(
                          text: _formatScore(entry.totalScore),
                          height: contentHeight * .4,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  Widget build(BuildContext context) {
    // Chiều rộng khả dụng thực tế của phần lõi badge (sau khi trừ padding 2 bên)
    final contentWidth = width * (1 - 0.16 * 2);

    return SizedBox(
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
              alignment: Alignment.center,
              // Giới hạn chiều ngang tối đa đúng bằng khoảng trống ruột badge
              child: SizedBox(
                width: contentWidth,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2, // Cho phép tối đa 2 dòng để không tràn chiều dọc
                  softWrap: true,
                  style: TextStyle(
                    color: const Color(0xFFFFF8E8),
                    fontWeight: FontWeight.w900,
                    // Đặt cỡ chữ cơ sở đủ lớn và line-height gọn
                    fontSize: height * 0.2,
                    height: 1.05,
                    shadows: const [
                      Shadow(color: Color(0xFF3C1E06), offset: Offset(0, 1)),
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

class _ProgressValue extends StatelessWidget {
  const _ProgressValue({required this.text, required this.height});

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          RankingAssets.coin,
          width: height,
          height: height,
          fit: BoxFit.contain,
        ),
        SizedBox(width: height * .14),
        Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: const Color(0xFF704019),
            fontSize: height * .72,
            height: 1,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Color(0x55FFF0B0), offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    ),
  );
}
