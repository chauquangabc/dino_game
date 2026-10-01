import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/farm_repository.dart';
import '../../data/farm_rewarded_ad_gateway.dart';
import '../../domain/farm_food.dart';
import '../../domain/farm_state.dart';
import '../widgets/farm_feedback.dart';
import '../widgets/farm_food_tray.dart';
import '../widgets/farm_landscape_layout.dart';
import '../widgets/farm_layout.dart';
import '../widgets/farm_pet_tray.dart';
import '../widgets/farm_portrait_layout.dart';

class FarmPage extends StatefulWidget {
  const FarmPage({
    super.key,
    this.repository,
    this.adGateway = const MockFarmRewardedAdGateway(),
  });

  final FarmRepository? repository;
  final FarmRewardedAdGateway adGateway;

  @override
  State<FarmPage> createState() => _FarmPageState();
}

class _FarmPageState extends State<FarmPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final FarmRepository _repository = widget.repository ?? FarmRepository();
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  final _focusNode = FocusNode();
  final _random = math.Random();
  final List<_BubbleData> _bubbles = [];
  final List<_CoinPlusData> _coinPlusEffects = [];
  FarmState? _state;
  Timer? _ticker;
  Timer? _toastTimer;
  StreamSubscription<void>? _changes;
  bool _foodOpen = false;
  bool _petsOpen = false;
  bool _busy = false;
  bool _petHovered = false;
  String? _toastText;
  int _bubbleId = 0;
  int _coinPlusId = 0;
  int _bubbleUnit = 0;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tickCount++;
      if (_tickCount % 30 == 0) {
        _reload();
      } else {
        setState(() {});
      }
    });
    _changes = _repository.changes.listen((_) => _reload());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _toastTimer?.cancel();
    _changes?.cancel();
    _clearBubbles();
    _bounce.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final next = await _repository.load();
    if (mounted) setState(() => _state = next);
  }

  Future<void> _run(Future<FarmState> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = await action();
      if (mounted) setState(() => _state = next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toastText = text);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toastText = null);
    });
  }

  Future<void> _feed(FarmFood food) async {
    final state = _state;
    if (state == null || _busy) return;
    if ((state.foodInventory[food.id] ?? 0) < 1) {
      await _acquire(food);
      return;
    }
    if (state.shouldConfirmFeed(DateTime.now())) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xfff7df9b),
          title: const Text('FEED NOW?'),
          content: Text(
            'There is still ${farmDuration(state.remainingAt(DateTime.now()))} '
            'of health left. Replace it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('FEED'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _run(() => _repository.feed(food.id));
    if (!mounted) return;
    setState(() => _foodOpen = false);
    _bounce.forward(from: 0);
    _showToast('${food.name} served!');
  }

  Future<void> _acquire(FarmFood food) async {
    switch (food.acquisition) {
      case FarmFoodAcquisition.coins:
        if (_state!.coins < food.price) {
          _showToast('Not enough coins');
          return;
        }
        await _run(() => _repository.buyOneFood(food.id));
        _showToast('+1 ${food.name}');
      case FarmFoodAcquisition.store:
        if (mounted) context.push('/store?category=pet');
      case FarmFoodAcquisition.rewardedAd:
        if (_state!.adGrantsLeft < 1) {
          _showToast('Come back tomorrow for more ads');
          return;
        }
        setState(() => _busy = true);
        final completed = await widget.adGateway.show();
        if (!mounted) return;
        setState(() => _busy = false);
        if (!completed) {
          _showToast('Ad not completed');
          return;
        }
        await _run(() => _repository.grantRewardedFood(food.id));
        _showToast('+1 ${food.name}');
    }
  }

  Future<void> _claimAll() async {
    final amount = _state?.pendingCoins ?? 0;
    if (amount < 1) return;
    _clearBubbles();
    await _run(_repository.claim);
    _showToast('+$amount coins');
  }

  void _spawnBubbles(Size size, Rect petRect) {
    final pending = _state?.pendingCoins ?? 0;
    _bounce.forward(from: 0);
    if (pending < 1 || _bubbles.length >= 8) return;
    var unreserved = pending - _bubbles.fold<int>(0, (sum, b) => sum + b.value);
    if (unreserved < 1) {
      _bubbleUnit = 0;
      return;
    }
    if (_bubbleUnit == 0) _bubbleUnit = math.max(1, (unreserved / 5).round());
    final count = math.min(8 - _bubbles.length, 1 + _random.nextInt(2));
    for (var i = 0; i < count && unreserved > 0; i++) {
      final varied = (_bubbleUnit * (.6 + _random.nextDouble() * .8)).round();
      final value = math.min(unreserved, math.max(1, varied));
      unreserved -= value;
      final id = _bubbleId++;
      final bubbleSize = (petRect.height * .46).clamp(34.0, 92.0);
      final center = Offset(
        (petRect.left + petRect.width * (.12 + _random.nextDouble() * .76))
            .clamp(bubbleSize / 2, size.width - bubbleSize / 2),
        (petRect.top + petRect.height * (.05 + _random.nextDouble() * .45))
            .clamp(bubbleSize / 2, size.height - bubbleSize / 2),
      );
      late Timer timer;
      timer = Timer(const Duration(seconds: 9), () {
        if (!mounted) return;
        for (final bubble in _bubbles) {
          if (bubble.id == id) {
            _popBubble(bubble, reward: false);
            break;
          }
        }
      });
      _bubbles.add(
        _BubbleData(
          id: id,
          value: value,
          center: center,
          size: bubbleSize,
          drift: Offset(
            (_random.nextDouble() * 2 - 1) * bubbleSize * .9,
            -bubbleSize * (1.1 + _random.nextDouble() * 1.3),
          ),
          createdAt: DateTime.now(),
          timer: timer,
        ),
      );
    }
    setState(() {});
  }

  Future<void> _popBubble(_BubbleData bubble, {required bool reward}) async {
    if (bubble.popping) return;
    bubble.timer.cancel();
    bubble.popping = true;
    final elapsed = DateTime.now().difference(bubble.createdAt).inMilliseconds;
    final progress = (elapsed / 9000).clamp(0.0, 1.0);
    final effectCenter =
        bubble.center + bubble.drift * Curves.easeOut.transform(progress);
    if (reward) {
      _coinPlusEffects.add(
        _CoinPlusData(
          id: _coinPlusId++,
          value: bubble.value,
          center: effectCenter,
          size: bubble.size,
        ),
      );
    }
    setState(() {});
    if (!reward) return;
    final next = await _repository.claim(bubble.value);
    if (mounted) setState(() => _state = next);
  }

  void _clearBubbles() {
    for (final bubble in _bubbles) {
      bubble.timer.cancel();
    }
    _bubbles.clear();
    _bubbleUnit = 0;
  }

  void _close() {
    _clearBubbles();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) => KeyboardListener(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: (event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _close();
      }
    },
    child: Scaffold(
      backgroundColor: const Color(0xff8fd0ef),
      body: _state == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) => _buildFarm(
                Size(constraints.maxWidth, constraints.maxHeight),
                _state!,
              ),
            ),
    ),
  );

  Widget _buildFarm(Size size, FarmState state) {
    final landscape = size.width > size.height * 1.15;
    void toggleFood() => setState(() {
      _foodOpen = !_foodOpen;
      _petsOpen = false;
    });
    void togglePets() => setState(() {
      _petsOpen = !_petsOpen;
      _foodOpen = false;
    });
    void tapPet(Rect rect) => _spawnBubbles(size, rect);
    void hoverPet(bool value) => setState(() => _petHovered = value);

    return Stack(
      children: [
        Positioned.fill(
          child: landscape
              ? FarmLandscapeLayout(
                  size: size,
                  safeTop: MediaQuery.paddingOf(context).top,
                  state: state,
                  busy: _busy,
                  petHovered: _petHovered,
                  bounce: _bounce,
                  onFeed: toggleFood,
                  onClaim: _claimAll,
                  onPets: togglePets,
                  onClose: _close,
                  onPetTap: tapPet,
                  onPetHoverChanged: hoverPet,
                  onFoodDropped: _feed,
                )
              : FarmPortraitLayout(
                  size: size,
                  safeTop: MediaQuery.paddingOf(context).top,
                  state: state,
                  busy: _busy,
                  petHovered: _petHovered,
                  bounce: _bounce,
                  onFeed: toggleFood,
                  onClaim: _claimAll,
                  onPets: togglePets,
                  onClose: _close,
                  onPetTap: tapPet,
                  onPetHoverChanged: hoverPet,
                  onFoodDropped: _feed,
                ),
        ),
        if (_foodOpen || _petsOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _foodOpen = false;
                _petsOpen = false;
              }),
              child: const ColoredBox(color: Color(0x26000000)),
            ),
          ),
        if (_foodOpen)
          FarmFoodTray(
            state: state,
            onSelect: (food) async {
              final next = await _repository.selectFood(food.id);
              if (mounted) setState(() => _state = next);
            },
            onFeed: _feed,
            onDragStarted: () => setState(() => _foodOpen = false),
          ),
        if (_petsOpen)
          FarmPetTray(
            state: state,
            onSelect: (id) async {
              final next = await _repository.selectPet(id);
              if (!mounted) return;
              setState(() {
                _state = next;
                _petsOpen = false;
              });
            },
          ),
        for (final bubble in _bubbles)
          Positioned(
            left: bubble.center.dx - bubble.size / 2,
            top: bubble.center.dy - bubble.size / 2,
            child: FarmCoinBubble(
              key: ValueKey(bubble.id),
              size: bubble.size,
              drift: bubble.drift,
              popping: bubble.popping,
              onTap: () => _popBubble(bubble, reward: true),
              onPopFinished: () {
                if (mounted) {
                  setState(
                    () => _bubbles.removeWhere((b) => b.id == bubble.id),
                  );
                }
              },
            ),
          ),
        for (final effect in _coinPlusEffects)
          Positioned(
            left: effect.center.dx - effect.size * .45,
            top: effect.center.dy - effect.size * .3,
            child: FarmCoinPlus(
              key: ValueKey(effect.id),
              value: effect.value,
              size: effect.size,
              onFinished: () {
                if (mounted) {
                  setState(
                    () =>
                        _coinPlusEffects.removeWhere((e) => e.id == effect.id),
                  );
                }
              },
            ),
          ),
        if (_toastText != null)
          SafeArea(
            child: Align(
              alignment: const Alignment(0, .86),
              child: IgnorePointer(child: FarmToast(text: _toastText!)),
            ),
          ),
      ],
    );
  }
}

class _BubbleData {
  _BubbleData({
    required this.id,
    required this.value,
    required this.center,
    required this.size,
    required this.drift,
    required this.createdAt,
    required this.timer,
  });

  final int id;
  final int value;
  final Offset center;
  final double size;
  final Offset drift;
  final DateTime createdAt;
  final Timer timer;
  bool popping = false;
}

class _CoinPlusData {
  const _CoinPlusData({
    required this.id,
    required this.value,
    required this.center,
    required this.size,
  });

  final int id;
  final int value;
  final Offset center;
  final double size;
}

extension FarmRouter on FarmPage {
  static const path = '/farm';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const FarmPage());
}
