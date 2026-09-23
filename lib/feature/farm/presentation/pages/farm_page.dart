import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FarmPage extends StatelessWidget {
  const FarmPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Farm')),
    body: const Center(child: Text('Farm')),
  );
}

extension FarmRouter on FarmPage {
  static const path = '/farm';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const FarmPage());
}
