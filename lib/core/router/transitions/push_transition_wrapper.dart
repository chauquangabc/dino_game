import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class PushTransitionWrapper extends CustomTransitionPage {
  PushTransitionWrapper({required super.child})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return CupertinoPageTransition(
            linearTransition: true,
            primaryRouteAnimation: animation,
            secondaryRouteAnimation: secondaryAnimation,
            child: child,
          );
        },
      );
}
