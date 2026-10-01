abstract interface class FarmRewardedAdGateway {
  Future<bool> show();
}

/// Local mock used until a rewarded-ad SDK is connected.
class MockFarmRewardedAdGateway implements FarmRewardedAdGateway {
  const MockFarmRewardedAdGateway({this.completes = true});
  final bool completes;

  @override
  Future<bool> show() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return completes;
  }
}
