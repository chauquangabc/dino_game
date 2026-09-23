import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LuckyWheelPage extends StatelessWidget {
  const LuckyWheelPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lucky Wheel')),
    body: const Center(child: Text('Lucky Wheel')),
  );
}

extension LuckyWheelRouter on LuckyWheelPage {
  static const path = '/lucky-wheel';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const LuckyWheelPage());
}
