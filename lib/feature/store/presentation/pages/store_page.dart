import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/store_repository.dart';
import '../../domain/store_category.dart';
import '../../domain/store_product.dart';
import '../../domain/store_state.dart';
import '../widgets/store_popup.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreRepository _repository = StoreRepository();
  final FocusNode _focusNode = FocusNode();
  StoreState _state = const StoreState();
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await _repository.load();
    if (!mounted) return;
    setState(() => _state = loaded);
  }

  void _selectCategory(StoreCategory category) {
    setState(() => _state = _state.copyWith(selectedCategory: category));
  }

  bool _isOwned(StoreProduct product) => _repository.isOwned(_state, product);

  Future<void> _buy(StoreProduct product) async {
    if (_state.purchaseInProgress) return;
    setState(() => _state = _state.copyWith(purchaseInProgress: true));
    final result = await _repository.purchase(_state, product);
    if (!mounted) return;
    setState(
      () => _state = result.state.copyWith(
        purchaseInProgress: false,
        message: result.message,
      ),
    );
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _state = _state.copyWith(clearMessage: true));
    });
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: const ColoredBox(color: Color(0x8C080C18)),
                ),
              ),
            ),
            Positioned.fill(
              child: StorePopup(
                state: _state,
                onClose: _close,
                onCategorySelected: _selectCategory,
                onBuy: _buy,
                isOwned: _isOwned,
              ),
            ),
            if (_state.message != null)
              SafeArea(
                child: Align(
                  alignment: const Alignment(0, .88),
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEB3C2008),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _state.message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFE7B3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension StoreRouter on StorePage {
  static const path = '/store';

  static GoRoute goRoute() => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      child: const StorePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
