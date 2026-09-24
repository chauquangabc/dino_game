import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/ranking_mock_data.dart';
import '../../domain/ranking_board.dart';
import '../../domain/ranking_state.dart';
import '../widgets/ranking_popup.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late RankingState _state;

  @override
  void initState() {
    super.initState();
    _state = RankingMockData.load();
  }

  void _selectBoard(RankingBoard board) {
    setState(() => _state = _state.copyWith(selectedBoard: board));
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: const ColoredBox(color: Color(0x99080C18)),
          ),
        ),
        Positioned.fill(
          child: RankingPopup(
            state: _state,
            onBoardSelected: _selectBoard,
            onClose: _close,
          ),
        ),
      ],
    ),
  );
}

extension RankingRouter on RankingPage {
  static const path = '/ranking';

  static GoRoute goRoute() => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 170),
      child: const RankingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
