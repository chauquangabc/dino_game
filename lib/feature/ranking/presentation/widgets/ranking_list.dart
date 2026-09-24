import 'package:flutter/material.dart';

import '../../domain/ranking_board.dart';
import '../../domain/ranking_entry.dart';
import 'ranking_row.dart';

class RankingList extends StatelessWidget {
  const RankingList({
    super.key,
    required this.entries,
    required this.board,
    required this.rowHeight,
  });

  final List<RankingEntry> entries;
  final RankingBoard board;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const RankingEmptyState();
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length,
      itemExtent: rowHeight,
      itemBuilder: (context, index) =>
          RankingRow(entry: entries[index], board: board, rowHeight: rowHeight),
    );
  }
}

class RankingEmptyState extends StatelessWidget {
  const RankingEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: .82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFD7A85C),
            size: 54,
          ),
          const SizedBox(height: 10),
          const FittedBox(
            child: Text(
              'NO RANKINGS YET',
              style: TextStyle(
                color: Color(0xFFFFE8B3),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete levels to join the rankings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFFF1D2).withValues(alpha: .78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
