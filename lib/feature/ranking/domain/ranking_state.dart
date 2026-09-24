import 'ranking_board.dart';
import 'ranking_entry.dart';

class RankingState {
  const RankingState({
    this.selectedBoard = RankingBoard.progress,
    this.progressEntries = const [],
    this.weeklyEntries = const [],
  });

  final RankingBoard selectedBoard;
  final List<RankingEntry> progressEntries;
  final List<RankingEntry> weeklyEntries;

  List<RankingEntry> get visibleEntries =>
      selectedBoard == RankingBoard.progress ? progressEntries : weeklyEntries;

  RankingState copyWith({RankingBoard? selectedBoard}) => RankingState(
    selectedBoard: selectedBoard ?? this.selectedBoard,
    progressEntries: progressEntries,
    weeklyEntries: weeklyEntries,
  );
}
