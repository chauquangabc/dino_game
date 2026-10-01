import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/lucky_wheel_repository.dart';
import '../../domain/lucky_wheel_catalog.dart';
import '../../domain/lucky_wheel_state.dart';
import '../widgets/lucky_wheel_popup.dart';

class LuckyWheelPage extends StatefulWidget {
  const LuckyWheelPage({super.key});

  @override
  State<LuckyWheelPage> createState() => _LuckyWheelPageState();
}

class _LuckyWheelPageState extends State<LuckyWheelPage> {
  final _repository = LuckyWheelRepository();
  final _focusNode = FocusNode();
  LuckyWheelState _state = const LuckyWheelState();
  double _wheelTurns = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final state = await _repository.load();
      if (!mounted) return;
      setState(() => _state = state);
    } catch (_) {
      if (mounted) {
        setState(() => _state = _state.copyWith(isLoading: false));
        _showMessage('Could not load rewards. Please reopen Lucky Wheel.');
      }
    }
  }

  Future<void> _plusTurn() async {
    if (_state.isLoading || _state.isSpinning || _state.isClaiming) return;
    try {
      final next = await _repository.plusTurn(_state);

      if (!mounted) return;

      setState(() {
        _state = next;
      });
    } catch (_) {
      if (mounted) _showMessage('Could not save the turn. Please try again.');
    }
  }

  Future<void> _spin() async {
    if (_state.isLoading || _state.isSpinning || _state.pendingResult != null) {
      return;
    }
    if (_state.spins <= 0) {
      _showMessage('No spins left today');
      return;
    }
    setState(
      () => _state = _state.copyWith(isSpinning: true, clearMessage: true),
    );
    try {
      final next = await _repository.spin(_state);
      final result = next.pendingResult;
      if (!mounted || result == null) {
        if (mounted) setState(() => _state = next.copyWith(isSpinning: false));
        return;
      }
      const segmentCount = 8;
      final target =
          ((segmentCount - result.segmentIndex) % segmentCount) / segmentCount;
      final current = ((_wheelTurns % 1) + 1) % 1;
      var delta = target - current;
      if (delta < 0) delta += 1;
      setState(() {
        _state = next.copyWith(isSpinning: true);
        _wheelTurns += 5 + delta;
      });
      await Future<void>.delayed(LuckyWheelCatalog.spinDuration);
      if (mounted) setState(() => _state = _state.copyWith(isSpinning: false));
    } catch (_) {
      await _load();
      if (mounted) {
        setState(() => _state = _state.copyWith(isSpinning: false));
        _showMessage('Could not finish the spin. Please try again.');
      }
    }
  }

  Future<void> _claim() async {
    if (_state.isClaiming) return;
    setState(() => _state = _state.copyWith(isClaiming: true));
    try {
      final next = await _repository.claim(_state);
      if (!mounted) return;
      setState(() => _state = next.copyWith(isClaiming: false));
    } catch (_) {
      await _load();
      if (mounted) {
        setState(() => _state = _state.copyWith(isClaiming: false));
        _showMessage('Could not save rewards. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    _messageTimer?.cancel();
    setState(() => _state = _state.copyWith(message: message));
    _messageTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _state = _state.copyWith(clearMessage: true));
    });
  }

  void _close() {
    if (!_state.isSpinning &&
        _state.pendingResult == null &&
        context.canPop()) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
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
    child: Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const ColoredBox(color: Color(0xA3080C18)),
            ),
          ),
          Positioned.fill(
            child: LuckyWheelPopup(
              state: _state,
              wheelTurns: _wheelTurns,
              onClose: _close,
              onSpin: _spin,
              onAdSpin: _plusTurn,
              onClaim: _claim,
            ),
          ),
          if (_state.pendingResult != null && !_state.isSpinning)
            Positioned.fill(
              child: RewardCard(
                result: _state.pendingResult!,
                isClaiming: _state.isClaiming,
                onClaim: _claim,
              ),
            ),
        ],
      ),
    ),
  );
}

extension LuckyWheelRouter on LuckyWheelPage {
  static const path = '/lucky-wheel';

  static GoRoute goRoute() => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      child: const LuckyWheelPage(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
