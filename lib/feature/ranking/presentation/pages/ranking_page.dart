import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ranking')),
    body: const Center(child: Text('Ranking')),
  );
}

extension RankingRouter on RankingPage {
  static const path = '/ranking';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const RankingPage());
}
