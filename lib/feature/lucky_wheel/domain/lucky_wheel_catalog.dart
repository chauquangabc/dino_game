import 'lucky_wheel_reward.dart';

abstract final class LuckyWheelCatalog {
  static const dailyFreeSpins = 1;
  static const streakDays = 7;
  static const streakRewardSpins = 1;
  static const claimedIdsLimit = 200;
  static const spinDuration = Duration(milliseconds: 4200);

  static const rewards = <LuckyWheelReward>[
    LuckyWheelReward(
      id: 'coin_small',
      type: LuckyWheelRewardType.coins,
      quantity: 100,
      weight: 28,
    ),
    LuckyWheelReward(
      id: 'hammer_1',
      type: LuckyWheelRewardType.hammer,
      quantity: 1,
      weight: 14,
    ),
    LuckyWheelReward(
      id: 'fragment_1',
      type: LuckyWheelRewardType.fragment,
      quantity: 1,
      weight: 16,
    ),
    LuckyWheelReward(
      id: 'swap_1',
      type: LuckyWheelRewardType.swap,
      quantity: 1,
      weight: 12,
    ),
    LuckyWheelReward(
      id: 'coin_large',
      type: LuckyWheelRewardType.coins,
      quantity: 500,
      weight: 10,
    ),
    LuckyWheelReward(
      id: 'hammer_2',
      type: LuckyWheelRewardType.hammer,
      quantity: 2,
      weight: 7,
    ),
    LuckyWheelReward(
      id: 'fragment_2',
      type: LuckyWheelRewardType.fragment,
      quantity: 2,
      weight: 8,
    ),
    LuckyWheelReward(
      id: 'swap_2',
      type: LuckyWheelRewardType.swap,
      quantity: 2,
      weight: 5,
    ),
  ];

  static LuckyWheelReward? byId(String id) {
    for (final reward in rewards) {
      if (reward.id == id) return reward;
    }
    return null;
  }
}
