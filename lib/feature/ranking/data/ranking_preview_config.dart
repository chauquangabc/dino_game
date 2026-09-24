enum RankingDataMode { empty, mock }

/// Temporary UI-preview switch. Change this value to [RankingDataMode.empty]
/// to inspect the empty state. This file is replaced by a repository once the
/// authenticated ranking backend is available.
abstract final class RankingPreviewConfig {
  static const mode = RankingDataMode.mock;
}
