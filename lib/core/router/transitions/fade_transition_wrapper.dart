import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionWrapper extends CustomTransitionPage {
  FadeTransitionWrapper({required super.child})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
            child: child,
          );
        },
      );
}
