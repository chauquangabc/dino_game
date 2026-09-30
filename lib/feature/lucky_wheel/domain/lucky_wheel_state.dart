import 'lucky_wheel_reward.dart';

class LuckyWheelState {
  const LuckyWheelState({
    this.spins = 0,
    this.streakDay = 0,
    this.isLoading = true,
    this.isSpinning = false,
    this.isClaiming = false,
    this.pendingResult,
    this.message,
  });

  final int spins;
  final int streakDay;
  final bool isLoading;
  final bool isSpinning;
  final bool isClaiming;
  final LuckyWheelResult? pendingResult;
  final String? message;

  LuckyWheelState copyWith({
    int? spins,
    int? streakDay,
    bool? isLoading,
    bool? isSpinning,
    bool? isClaiming,
    LuckyWheelResult? pendingResult,
    bool clearPending = false,
    String? message,
    bool clearMessage = false,
  }) => LuckyWheelState(
    spins: spins ?? this.spins,
    streakDay: streakDay ?? this.streakDay,
    isLoading: isLoading ?? this.isLoading,
    isSpinning: isSpinning ?? this.isSpinning,
    isClaiming: isClaiming ?? this.isClaiming,
    pendingResult: clearPending ? null : pendingResult ?? this.pendingResult,
    message: clearMessage ? null : message ?? this.message,
  );
}
