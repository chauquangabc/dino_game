import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Store')),
    body: const Center(child: Text('Store')),
  );
}

extension StoreRouter on StorePage {
  static const path = '/store';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const StorePage());
}
