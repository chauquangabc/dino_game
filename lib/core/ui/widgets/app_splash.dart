import 'package:flutter/material.dart';

class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  static const backgroundColor = Color(0xff183b31);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Image(
              image: AssetImage('assets/splash/splash.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
