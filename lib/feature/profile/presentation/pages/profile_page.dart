import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: const Center(child: Text('Profile')),
  );
}

extension ProfileRouter on ProfilePage {
  static const path = '/profile';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const ProfilePage());
}
